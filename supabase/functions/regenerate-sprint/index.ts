import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";
import { ApiError, errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
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
  RegenerateSprintBody,
  RegenerateSprintResult,
  SkillTreeNodeDraft,
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

    const { data: sprint, error: sprintError } = await supabaseAdmin
      .from("sprints")
      .select("*")
      .eq("id", body.sprintId)
      .maybeSingle();

    if (sprintError || !sprint) {
      throw new ApiError("Sprint not found", 404);
    }

    const { data: goal, error: goalError } = await supabaseAdmin
      .from("goals")
      .select("*")
      .eq("id", sprint.goal_id)
      .maybeSingle();

    if (goalError || !goal) {
      throw new ApiError("Goal not found", 404);
    }

    if (goal.user_id !== user.id) {
      throw new ApiError("Forbidden", 403);
    }

    const { data: sprintTasks } = await supabaseAdmin
      .from("sprint_tasks")
      .select("*")
      .eq("sprint_id", sprint.id);

    const validTaskIds = new Set((sprintTasks ?? []).map((task) => task.id));
    for (const update of body.statusUpdates ?? []) {
      if (!validTaskIds.has(update.taskId)) {
        throw new ApiError(
          "Status update refers to a task that does not belong to the sprint",
          400,
        );
      }
      const { error: updateError } = await supabaseAdmin
        .from("sprint_tasks")
        .update({ status: update.status })
        .eq("id", update.taskId)
        .eq("sprint_id", sprint.id);

      if (updateError) {
        throw new ApiError("Failed to update sprint task", 500);
      }
    }

    const { data: refreshedTasks } = await supabaseAdmin
      .from("sprint_tasks")
      .select("*")
      .eq("sprint_id", sprint.id);

    const taskStats = summarizeTaskStatuses(
      refreshedTasks ?? [] as SprintTaskRecord[],
    );

    const { data: latestSprint } = await supabaseAdmin
      .from("sprints")
      .select("sprint_number")
      .eq("goal_id", goal.id)
      .order("sprint_number", { ascending: false })
      .limit(1)
      .maybeSingle();

    const previousLengthDays = Math.max(
      6,
      Math.round(
        (new Date(sprint.to_date).getTime() -
          new Date(sprint.from_date).getTime()) /
          MS_PER_DAY,
      ),
    );

    const nextSprintNumber = (latestSprint?.sprint_number ?? 0) + 1;
    const fromDate = new Date(sprint.to_date);
    fromDate.setDate(fromDate.getDate() + 1);
    const toDate = new Date(fromDate);
    toDate.setDate(fromDate.getDate() + previousLengthDays);

    const { data: skillTree } = await supabaseAdmin
      .from("skill_trees")
      .select("*")
      .eq("goal_id", goal.id)
      .maybeSingle();

    const nodeRecords = skillTree
      ? (
        await supabaseAdmin
          .from("skill_tree_nodes")
          .select("*")
          .eq("skill_tree_id", skillTree.id)
      ).data ?? []
      : [];

    let nodeDrafts: SkillTreeNodeDraft[] = nodeRecords.map((node) => ({
      nodePath: node.node_path,
      title: node.title,
      level: node.level,
      focusHours: node.focus_hours,
      payload: node.payload ?? {},
    }));

    if (nodeDrafts.length === 0) {
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

    const { data: nextSprint, error: nextSprintError } = await supabaseAdmin
      .from("sprints")
      .insert([
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
      ])
      .select("*")
      .single();

    if (nextSprintError || !nextSprint) {
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

    const { data: insertedTasks, error: tasksError } = await supabaseAdmin
      .from("sprint_tasks")
      .insert(taskPayloads)
      .select("*");

    if (tasksError || !insertedTasks) {
      throw new ApiError("Failed to persist regenerated sprint tasks", 500);
    }

    const { data: progressLog, error: logError } = await supabaseAdmin
      .from("progress_logs")
      .insert([
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
      ])
      .select("*")
      .single();

    if (logError || !progressLog) {
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
