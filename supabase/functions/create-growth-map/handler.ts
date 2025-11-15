import { ApiError } from "../_shared/errorHandler.ts";
import type {
  CreateGrowthMapBody,
  CreateGrowthMapResult,
  GoalRecord,
  SkillTreeNodeDraft,
  SkillTreeNodeRecord,
  SkillTreeRecord,
  SprintRecord,
  SprintTaskDraft,
  SprintTaskRecord,
} from "../_shared/types.ts";
import {
  generateSkillTreeDraft,
  planInitialSprint,
} from "../_shared/llmClient.ts";
import { insertRecords } from "../_shared/restClient.ts";

export interface CreateGrowthMapDeps {
  insertRecords: typeof insertRecords;
  generateSkillTreeDraft: typeof generateSkillTreeDraft;
  planInitialSprint: typeof planInitialSprint;
}

function validateGoalInput(payload: CreateGrowthMapBody) {
  if (!payload.title?.trim() || !payload.description?.trim()) {
    throw new ApiError("Goal title and description are required", 400);
  }
  if (!Number.isFinite(payload.horizonMonths) || payload.horizonMonths <= 0) {
    throw new ApiError("horizonMonths must be a positive number", 400);
  }
  if (!Number.isFinite(payload.dailyMinutes) || payload.dailyMinutes <= 0) {
    throw new ApiError("dailyMinutes must be a positive number", 400);
  }
}

export async function createGrowthMap(
  payload: CreateGrowthMapBody,
  user: { id: string },
  deps: CreateGrowthMapDeps,
): Promise<CreateGrowthMapResult> {
  validateGoalInput(payload);
  const insert = deps.insertRecords;

  const [goal] = await insert<GoalRecord>("goals", [
    {
      user_id: user.id,
      title: payload.title,
      description: payload.description,
      horizon_months: payload.horizonMonths,
      daily_minutes: payload.dailyMinutes,
      status: "active",
      priority: 0,
      target_date: payload.targetDate ?? null,
    },
  ]);

  if (!goal) {
    throw new ApiError("Failed to insert goal", 500);
  }

  const draft = await deps.generateSkillTreeDraft(payload);

  const [tree] = await insert<SkillTreeRecord>("skill_trees", [
    {
      goal_id: goal.id,
      tree_json: draft.treeJson,
      generated_by: "create-growth-map",
      version: 1,
    },
  ]);

  if (!tree) {
    throw new ApiError("Failed to persist skill tree", 500);
  }

  const nodePayloads = draft.nodes.map((node) => ({
    skill_tree_id: tree.id,
    node_path: node.nodePath,
    title: node.title,
    level: node.level,
    focus_hours: node.focusHours,
    payload: node.payload,
  }));

  const insertedNodes = await insert<SkillTreeNodeRecord>(
    "skill_tree_nodes",
    nodePayloads,
  );

  if (!insertedNodes.length) {
    throw new ApiError("Failed to persist skill tree nodes", 500);
  }

  const sprintPlan = deps.planInitialSprint(payload, draft.nodes);

  const [sprint] = await insert<SprintRecord>("sprints", [
    {
      goal_id: goal.id,
      sprint_number: sprintPlan.sprintNumber,
      from_date: sprintPlan.fromDate,
      to_date: sprintPlan.toDate,
      status: "planned",
      summary: sprintPlan.summary,
      metrics: { horizonMonths: payload.horizonMonths },
    },
  ]);

  if (!sprint) {
    throw new ApiError("Failed to persist sprint", 500);
  }

  const nodeMap = new Map<string, SkillTreeNodeRecord>();
  insertedNodes.forEach((node) => nodeMap.set(node.node_path, node));

  const taskPayloads = buildTaskPayloads(sprintPlan.tasks, sprint.id, nodeMap);
  const insertedTasks = await insert<SprintTaskRecord>(
    "sprint_tasks",
    taskPayloads,
  );

  if (!insertedTasks.length) {
    throw new ApiError("Failed to persist sprint tasks", 500);
  }

  return {
    goal,
    skillTree: { ...tree, nodes: insertedNodes },
    sprint: { ...sprint, tasks: insertedTasks },
  };
}

function buildTaskPayloads(
  tasks: SprintTaskDraft[],
  sprintId: string,
  nodeMap: Map<string, SkillTreeNodeRecord>,
) {
  return tasks.map((task) => ({
    sprint_id: sprintId,
    skill_node_id: task.nodePath
      ? nodeMap.get(task.nodePath)?.id ?? null
      : null,
    title: task.title,
    description: task.description,
    difficulty: task.difficulty,
    status: "pending",
    due_date: task.dueDate ?? null,
    estimated_minutes: task.estimatedMinutes ?? null,
  }));
}
