import { assertEquals } from "https://deno.land/std@0.214.0/testing/asserts.ts";
import type { SprintTaskRecord } from "./types.ts";
import { summarizeTaskStatuses } from "./sprintStats.ts";

const mockTasks: SprintTaskRecord[] = [
  {
    id: "1",
    sprint_id: "s",
    skill_node_id: null,
    title: "A",
    description: "",
    difficulty: "low",
    status: "done",
    due_date: null,
    estimated_minutes: null,
    created_at: "",
    updated_at: "",
  },
  {
    id: "2",
    sprint_id: "s",
    skill_node_id: null,
    title: "B",
    description: "",
    difficulty: "medium",
    status: "pending",
    due_date: null,
    estimated_minutes: null,
    created_at: "",
    updated_at: "",
  },
  {
    id: "3",
    sprint_id: "s",
    skill_node_id: null,
    title: "C",
    description: "",
    difficulty: "high",
    status: "skipped",
    due_date: null,
    estimated_minutes: null,
    created_at: "",
    updated_at: "",
  },
  {
    id: "4",
    sprint_id: "s",
    skill_node_id: null,
    title: "D",
    description: "",
    difficulty: "low",
    status: "done",
    due_date: null,
    estimated_minutes: null,
    created_at: "",
    updated_at: "",
  },
];

Deno.test("summarizeTaskStatuses calculates counts", () => {
  const summary = summarizeTaskStatuses(mockTasks);
  assertEquals(summary.completed, 2);
  assertEquals(summary.pending, 1);
  assertEquals(summary.skipped, 1);
  assertEquals(summary.total, 4);
});
