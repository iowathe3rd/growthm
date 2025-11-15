import { assertEquals } from "https://deno.land/std@0.214.0/testing/asserts.ts";
import { regenerateSprint } from "./handler.ts";

Deno.test("regenerateSprint creates new sprint and log", async () => {
  const body = { sprintId: "sprint-1" };
  const user = { id: "user-1" };
  const deps = {
    selectSingleRecord: async (table: string) => {
      if (table === "sprints") {
        return {
          id: "sprint-1",
          goal_id: "goal-1",
          sprint_number: 1,
          from_date: "2025-01-01",
          to_date: "2025-01-07",
          status: "completed",
          summary: "",
          metrics: {},
          created_at: "",
          updated_at: "",
        };
      }
      if (table === "goals") {
        return {
          id: "goal-1",
          user_id: user.id,
          title: "Goal",
          description: "",
          horizon_months: 3,
          daily_minutes: 60,
          status: "active",
          priority: 0,
          target_date: null,
          created_at: "",
          updated_at: "",
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
      if (table === "sprint_tasks") {
        return [{
          id: "task-1",
          sprint_id: "sprint-1",
          skill_node_id: null,
          title: "Old Task",
          description: "",
          difficulty: "low",
          status: "pending",
          due_date: null,
          estimated_minutes: null,
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
          status: "completed",
          summary: "",
          metrics: {},
          created_at: "",
          updated_at: "",
        }];
      }
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
      return [];
    },
    insertRecords: async (table: string) => {
      if (table === "sprints") {
        return [{
          id: "sprint-2",
          goal_id: "goal-1",
          sprint_number: 2,
          from_date: "2025-01-08",
          to_date: "2025-01-14",
          status: "planned",
          summary: "",
          metrics: {},
          created_at: "",
          updated_at: "",
        }];
      }
      if (table === "sprint_tasks") {
        return [{
          id: "task-2",
          sprint_id: "sprint-2",
          skill_node_id: "node-1",
          title: "New Task",
          description: "",
          difficulty: "low",
          status: "pending",
          due_date: null,
          estimated_minutes: null,
          created_at: "",
          updated_at: "",
        }];
      }
      if (table === "progress_logs") {
        return [{
          id: "log-1",
          user_id: user.id,
          goal_id: "goal-1",
          sprint_id: "sprint-1",
          payload: {},
          recorded_at: "",
          created_at: "",
        }];
      }
      return [];
    },
    updateRecords: async () => [],
    planAdaptiveSprint: async () => ({
      sprintNumber: 2,
      fromDate: "2025-01-08",
      toDate: "2025-01-14",
      summary: "",
      tasks: [
        {
          title: "New Task",
          description: "",
          difficulty: "low",
          dueDate: "2025-01-12",
          estimatedMinutes: 30,
          nodePath: "root",
        },
      ],
    }),
    generateSkillTreeDraft: async () => ({ treeJson: {}, nodes: [] }),
  };

  const result = await regenerateSprint(body as any, user, deps as any);
  assertEquals(result.sprint.id, "sprint-2");
  assertEquals(result.progressLog.id, "log-1");
});
