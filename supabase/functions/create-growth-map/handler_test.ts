import { assertEquals } from "https://deno.land/std@0.214.0/testing/asserts.ts";
import { createGrowthMap } from "./handler.ts";

const payload = {
  title: "Test Goal",
  description: "Describe",
  horizonMonths: 4,
  dailyMinutes: 60,
};

const user = { id: "user-1" };

const deps = {
  insertRecords: async (table: string, _payload: unknown) => {
    switch (table) {
      case "goals":
        return [{
          id: "goal-1",
          user_id: user.id,
          title: payload.title,
          description: payload.description,
          horizon_months: payload.horizonMonths,
          daily_minutes: payload.dailyMinutes,
          status: "active",
          priority: 0,
          target_date: null,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        }];
      case "skill_trees":
        return [{
          id: "tree-1",
          goal_id: "goal-1",
          tree_json: { nodes: [] },
          generated_by: "create-growth-map",
          version: 1,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        }];
      case "skill_tree_nodes":
        return [{
          id: "node-1",
          skill_tree_id: "tree-1",
          node_path: "root.node",
          title: "Node",
          level: 1,
          focus_hours: 10,
          payload: {},
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        }];
      case "sprints":
        return [{
          id: "sprint-1",
          goal_id: "goal-1",
          sprint_number: 1,
          from_date: "2025-01-01",
          to_date: "2025-01-07",
          status: "planned",
          summary: "Summary",
          metrics: { horizonMonths: payload.horizonMonths },
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        }];
      case "sprint_tasks":
        return [{
          id: "task-1",
          sprint_id: "sprint-1",
          skill_node_id: "node-1",
          title: "Task",
          description: "Task",
          difficulty: "low",
          status: "pending",
          due_date: "2025-01-05",
          estimated_minutes: 20,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        }];
      default:
        return [];
    }
  },
  generateSkillTreeDraft: async () => ({
    treeJson: { nodes: [] },
    nodes: [
      {
        nodePath: "root.node",
        title: "Node",
        level: 1,
        focusHours: 10,
        payload: {},
      },
    ],
  }),
  planInitialSprint: () => ({
    sprintNumber: 1,
    fromDate: "2025-01-01",
    toDate: "2025-01-07",
    summary: "Summary",
    tasks: [
      {
        title: "Task",
        description: "Task",
        difficulty: "low",
        dueDate: "2025-01-05",
        estimatedMinutes: 20,
        nodePath: "root.node",
      },
    ],
  }),
};

Deno.test("createGrowthMap returns the aggregated goal bundle", async () => {
  const result = await createGrowthMap(payload, user, deps as any);
  assertEquals(result.goal.id, "goal-1");
  assertEquals(result.skillTree.nodes.length, 1);
  assertEquals(result.sprint.tasks[0].title, "Task");
});
