import { ApiError } from "../_shared/errorHandler.ts";
import type {
  GoalDetailResponse,
  GoalRecord,
  SkillTreeNodeRecord,
  SkillTreeRecord,
  SprintRecord,
  SprintTaskRecord,
} from "../_shared/types.ts";
import { selectRecords, selectSingleRecord } from "../_shared/restClient.ts";

export interface GetGoalDetailDeps {
  selectSingleRecord: typeof selectSingleRecord;
  selectRecords: typeof selectRecords;
}

export async function getGoalDetail(
  goalId: string,
  user: { id: string },
  deps: GetGoalDetailDeps,
): Promise<GoalDetailResponse> {
  const goal = await deps.selectSingleRecord<GoalRecord>("goals", {
    id: `eq.${goalId}`,
  });
  if (!goal) {
    throw new ApiError("Goal not found", 404);
  }
  if (goal.user_id !== user.id) {
    throw new ApiError("Forbidden", 403);
  }

  const skillTree = await deps.selectSingleRecord<SkillTreeRecord>(
    "skill_trees",
    { goal_id: `eq.${goalId}` },
  );
  const nodes = skillTree
    ? await deps.selectRecords<SkillTreeNodeRecord>("skill_tree_nodes", {
      skill_tree_id: `eq.${skillTree.id}`,
    })
    : [];

  const [latestSprint] = await deps.selectRecords<SprintRecord>("sprints", {
    goal_id: `eq.${goalId}`,
    order: "sprint_number.desc",
    limit: 1,
  });

  let latestSprintWithTasks = null;
  if (latestSprint) {
    const sprintTasks = await deps.selectRecords<SprintTaskRecord>(
      "sprint_tasks",
      { sprint_id: `eq.${latestSprint.id}` },
    );
    latestSprintWithTasks = { ...latestSprint, tasks: sprintTasks };
  }

  return {
    goal,
    skillTree: skillTree
      ? {
        ...skillTree,
        nodes,
      }
      : null,
    latestSprint: latestSprintWithTasks,
  };
}
