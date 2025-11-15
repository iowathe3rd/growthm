import { assertEquals } from "https://deno.land/std@0.214.0/testing/asserts.ts";
import { getGoalDetail } from "./handler.ts";

const user = { id: "user-1" };

Deno.test("getGoalDetail returns detail when available", async () => {
  const deps = {
    selectSingleRecord: async (table: string) => {
      if (table === "goals") {
        return {
          id: "goal-1",
          user_id: user.id,
          title: "Goal",
          description: "desc",
          horizon_months: 3,
          daily_minutes: 60,
          status: "active",
          priority: 0,
          target_date: null,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        };
      }
      if (table === "skill_trees") {
        return {
          id: "tree-1",
          goal_id: "goal-1",
          tree_json: {},
          generated_by: "",
          version: 1,
          created_at: "",
          updated_at: "",
        };
      }
      return null;
    },
    selectRecords: async (table: string) => {
      if (table === "skill_tree_nodes") {
        return [{
          id: "node-1",
          skill_tree_id: "tree-1",
          node_path: "root",
          title: "Node",
          level: 1,
          focus_hours: 10,
          payload: {},
          created_at: "",
          updated_at: "",
        }];
      }
      if (table === "sprints") {
        return [{
          id: "sprint-1",
          goal_id: "goal-1",
          sprint_number: 1,
          from_date: "2025-01-01",
          to_date: "2025-01-07",
          status: "planned",
          summary: null,
          metrics: {},
          created_at: "",
          updated_at: "",
        }];
      }
      if (table === "sprint_tasks") {
        return [{
          id: "task-1",
          sprint_id: "sprint-1",
          skill_node_id: null,
          title: "Task",
          description: "",
          difficulty: "low",
          status: "pending",
          due_date: null,
          estimated_minutes: null,
          created_at: "",
          updated_at: "",
        }];
      }
      return [];
    },
  };

  const response = await getGoalDetail("goal-1", user, deps as any);
  assertEquals(response.goal.id, "goal-1");
  assertEquals(response.skillTree?.nodes.length, 1);
  assertEquals(response.latestSprint?.tasks[0].id, "task-1");
});
