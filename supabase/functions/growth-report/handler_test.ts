import { assertEquals } from "https://deno.land/std@0.214.0/testing/asserts.ts";
import { getGrowthReport } from "./handler.ts";

Deno.test("getGrowthReport aggregates sprints", async () => {
  const user = { id: "user-1" };
  const body = { goalId: "goal-1" };

  const deps = {
    selectSingleRecord: async (table: string) => {
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
      return null;
    },
    selectRecords: async (table: string) => {
      if (table === "sprints") {
        return [{
          id: "sprint-1",
          goal_id: "goal-1",
          sprint_number: 1,
          from_date: "2025-01-01",
          to_date: "2025-01-07",
          status: "planned",
          summary: "",
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
          status: "done",
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
          recorded_at: "2025-01-07T00:00:00Z",
          created_at: "",
        }];
      }
      return [];
    },
    generateGrowthReport: async () => ({
      narrative: "narrative",
      recommendations: ["recommendation"],
    }),
  };

  const report = await getGrowthReport(body as any, user, deps as any);
  assertEquals(report.goal.id, "goal-1");
  assertEquals(report.sprintSummaries.length, 1);
  assertEquals(report.progressLogs.length, 1);
});
