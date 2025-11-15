import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { ApiError, errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import {
  insertRecords,
  selectRecords,
  selectSingleRecord,
  updateRecords,
} from "../_shared/restClient.ts";
import {
  generateSkillTreeDraft,
  goalRecordToGoalInput,
  planAdaptiveSprint,
} from "../_shared/llmClient.ts";
import {
  buildProgressPayload,
  summarizeTaskStatuses,
} from "../_shared/sprintStats.ts";
import type {
  GoalRecord,
  ProgressLogRecord,
  RegenerateSprintBody,
  RegenerateSprintResult,
  SkillTreeNodeDraft,
  SkillTreeNodeRecord,
  SkillTreeRecord,
  SprintRecord,
  SprintTaskRecord,
} from "../_shared/types.ts";

const MS_PER_DAY = 24 * 60 * 60 * 1000;

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(null, { status: 405, headers: { Allow: "POST" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const body = (await req.json()) as RegenerateSprintBody;
    if (!body.sprintId?.trim()) {
      throw new ApiError("sprintId is required", 400);
    }

    const sprint = await selectSingleRecord<SprintRecord>("sprints", {
      id: `eq.${body.sprintId}`,
    });
    if (!sprint) {
      throw new ApiError("Sprint not found", 404);
    }

    const goal = await selectSingleRecord<GoalRecord>("goals", {
      id: `eq.${sprint.goal_id}`,
    });
    if (!goal) {
      throw new ApiError("Goal not found", 404);
    }

    if (goal.user_id !== user.id) {
      throw new ApiError("Forbidden", 403);
    }

    const sprintTasks = await selectRecords<SprintTaskRecord>("sprint_tasks", {
      sprint_id: `eq.${sprint.id}`,
    });
    const validTaskIds = new Set(sprintTasks.map((task) => task.id));

    for (const update of body.statusUpdates ?? []) {
      if (!validTaskIds.has(update.taskId)) {
        throw new ApiError(
          "Status update refers to a task that does not belong to the sprint",
          400,
        );
      }
      await updateRecords("sprint_tasks", { status: update.status }, {
        id: `eq.${update.taskId}`,
        sprint_id: `eq.${sprint.id}`,
      });
    }

    const refreshedTasks = await selectRecords<SprintTaskRecord>(
      "sprint_tasks",
      { sprint_id: `eq.${sprint.id}` },
    );

    const taskStats = summarizeTaskStatuses(refreshedTasks);

    const [latestSprint] = await selectRecords<SprintRecord>("sprints", {
      goal_id: `eq.${goal.id}`,
      order: "sprint_number.desc",
      limit: 1,
    });

    const previousLengthDays = Math.max(
      6,
      Math.round(
        (new Date(sprint.to_date).getTime() -
          new Date(sprint.from_date).getTime()) / MS_PER_DAY,
      ),
    );

    const nextSprintNumber = (latestSprint?.sprint_number ?? 0) + 1;
    const fromDate = new Date(sprint.to_date);
    fromDate.setDate(fromDate.getDate() + 1);
    const toDate = new Date(fromDate);
    toDate.setDate(fromDate.getDate() + previousLengthDays);

    const skillTree = await selectSingleRecord<SkillTreeRecord>("skill_trees", {
      goal_id: `eq.${goal.id}`,
    });

    const nodeRecords = skillTree
      ? await selectRecords<SkillTreeNodeRecord>("skill_tree_nodes", {
        skill_tree_id: `eq.${skillTree.id}`,
      })
      : [];

    let nodeDrafts: SkillTreeNodeDraft[] = nodeRecords.map((node) => ({
      nodePath: node.node_path,
      title: node.title,
      level: node.level,
      focusHours: node.focus_hours,
      payload: node.payload ?? {},
    }));

    if (!nodeDrafts.length) {
      const fallback = await generateSkillTreeDraft(
        goalRecordToGoalInput(goal),
      );
      nodeDrafts = fallback.nodes;
    }

    const sprintPlan = await planAdaptiveSprint(
      goalRecordToGoalInput(goal),
      nodeDrafts,
      nextSprintNumber,
      fromDate,
      toDate,
      {
        completed: taskStats.completed,
        pending: taskStats.pending,
        skipped: taskStats.skipped,
        feedback: body.feedback,
        feelingTags: body.feelingTags ?? [],
      },
    );

    const [nextSprint] = await insertRecords<SprintRecord>("sprints", [
      {
        goal_id: goal.id,
        sprint_number: sprintPlan.sprintNumber,
        from_date: sprintPlan.fromDate,
        to_date: sprintPlan.toDate,
        status: "planned",
        summary: sprintPlan.summary,
        metrics: {
          completed: taskStats.completed,
          pending: taskStats.pending,
          skipped: taskStats.skipped,
          feedback: body.feedback ?? null,
          feelingTags: body.feelingTags ?? [],
        },
      },
    ]);

    if (!nextSprint) {
      throw new ApiError("Failed to persist regenerated sprint", 500);
    }

    const nodeMap = new Map<string, string>();
    nodeRecords.forEach((node) => nodeMap.set(node.node_path, node.id));

    const taskPayloads = sprintPlan.tasks.map((task) => ({
      sprint_id: nextSprint.id,
      skill_node_id: task.nodePath ? nodeMap.get(task.nodePath) ?? null : null,
      title: task.title,
      description: task.description,
      difficulty: task.difficulty,
      status: "pending",
      due_date: task.dueDate ?? null,
      estimated_minutes: task.estimatedMinutes ?? null,
    }));

    const insertedTasks = await insertRecords<SprintTaskRecord>(
      "sprint_tasks",
      taskPayloads,
    );

    if (!insertedTasks.length) {
      throw new ApiError("Failed to persist regenerated sprint tasks", 500);
    }

    const [progressLog] = await insertRecords<ProgressLogRecord>(
      "progress_logs",
      [
        {
          user_id: user.id,
          goal_id: goal.id,
          sprint_id: sprint.id,
          payload: buildProgressPayload(
            taskStats,
            body.statusUpdates ?? [],
            body.feedback,
            body.feelingTags ?? [],
          ),
        },
      ],
    );

    if (!progressLog) {
      throw new ApiError("Failed to persist progress log", 500);
    }

    const response: RegenerateSprintResult = {
      sprint: { ...nextSprint, tasks: insertedTasks },
      progressLog,
    };

    return new Response(JSON.stringify(response), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
