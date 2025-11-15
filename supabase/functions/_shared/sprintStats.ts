import type { SprintTaskRecord, TaskStatusUpdate } from "./types.ts";

export interface TaskSummary {
  completed: number;
  pending: number;
  skipped: number;
  total: number;
}

export function summarizeTaskStatuses(tasks: SprintTaskRecord[]): TaskSummary {
  const summary: TaskSummary = {
    completed: 0,
    pending: 0,
    skipped: 0,
    total: tasks.length,
  };
  tasks.forEach((task) => {
    if (task.status === "done") summary.completed += 1;
    if (task.status === "pending") summary.pending += 1;
    if (task.status === "skipped") summary.skipped += 1;
  });
  return summary;
}

export function buildProgressPayload(
  stats: TaskSummary,
  updates: TaskStatusUpdate[] = [],
  feedback?: string,
  feelingTags: string[] = [],
): Record<string, unknown> {
  return {
    completed: stats.completed,
    pending: stats.pending,
    skipped: stats.skipped,
    total: stats.total,
    updates: updates.map((update) => ({
      taskId: update.taskId,
      status: update.status,
      notes: update.notes ?? null,
    })),
    feedback: feedback ?? null,
    feelingTags,
  };
}
