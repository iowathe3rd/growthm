import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { ApiError, errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { selectRecords, selectSingleRecord } from "../_shared/restClient.ts";
import type {
  GoalDetailResponse,
  GoalRecord,
  SkillTreeNodeRecord,
  SkillTreeRecord,
  SprintRecord,
  SprintTaskRecord,
} from "../_shared/types.ts";

serve(async (req) => {
  try {
    if (req.method !== "GET") {
      return new Response(null, { status: 405, headers: { Allow: "GET" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const url = new URL(req.url);
    const goalId = url.searchParams.get("goal_id")?.trim();
    if (!goalId) {
      throw new ApiError("goal_id is required", 400);
    }

    const goal = await selectSingleRecord<GoalRecord>("goals", {
      id: `eq.${goalId}`,
    });

    if (!goal) {
      throw new ApiError("Goal not found", 404);
    }

    if (goal.user_id !== user.id) {
      throw new ApiError("Forbidden", 403);
    }

    const skillTree = await selectSingleRecord<SkillTreeRecord>("skill_trees", {
      goal_id: `eq.${goalId}`,
    });

    const nodes = skillTree
      ? await selectRecords<SkillTreeNodeRecord>("skill_tree_nodes", {
        skill_tree_id: `eq.${skillTree.id}`,
      })
      : [];

    const [latestSprint] = await selectRecords<SprintRecord>("sprints", {
      goal_id: `eq.${goalId}`,
      order: "sprint_number.desc",
      limit: 1,
      select: "*",
    });

    let latestSprintWithTasks = null;
    if (latestSprint) {
      const sprintTasks = await selectRecords<SprintTaskRecord>(
        "sprint_tasks",
        { sprint_id: `eq.${latestSprint.id}` },
      );
      latestSprintWithTasks = { ...latestSprint, tasks: sprintTasks };
    }

    const response: GoalDetailResponse = {
      goal,
      skillTree: skillTree
        ? {
          ...skillTree,
          nodes,
        }
        : null,
      latestSprint: latestSprintWithTasks,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});
