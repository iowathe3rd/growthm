import { ApiError } from "../_shared/errorHandler.ts";
import { goalRecordToGoalInput } from "../_shared/llmClient.ts";
import type { generateGrowthReport } from "../_shared/llmClient.ts";
import { summarizeTaskStatuses } from "../_shared/sprintStats.ts";
import type {
  GoalRecord,
  GrowthReportBody,
  GrowthReportResult,
  ProgressLogRecord,
  SprintRecord,
  SprintSummary,
  SprintTaskRecord,
} from "../_shared/types.ts";
import type {
  selectRecords,
  selectSingleRecord,
} from "../_shared/restClient.ts";

const DEFAULT_SPRINTS = 3;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export interface GrowthReportDeps {
  selectSingleRecord: typeof selectSingleRecord;
  selectRecords: typeof selectRecords;
  generateGrowthReport: typeof generateGrowthReport;
}

function parseDateOrDefault(value: string | undefined, fallback: Date): Date {
  if (!value) {
    return fallback;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return fallback;
  }
  return parsed;
}

export async function getGrowthReport(
  body: GrowthReportBody,
  user: { id: string },
  deps: GrowthReportDeps,
): Promise<GrowthReportResult> {
  if (!body.goalId?.trim()) {
    throw new ApiError("goalId is required", 400);
  }

  const goal = await deps.selectSingleRecord<GoalRecord>("goals", {
    id: `eq.${body.goalId}`,
  });
  if (!goal) {
    throw new ApiError("Goal not found", 404);
  }

  if (goal.user_id !== user.id) {
    throw new ApiError("Forbidden", 403);
  }

  const sinceDate = parseDateOrDefault(
    body.since,
    new Date(Date.now() - 30 * MS_PER_DAY),
  );
  const untilDate = parseDateOrDefault(body.until, new Date());

  if (sinceDate > untilDate) {
    throw new ApiError("since must be before until", 400);
  }

  const includeSprints = Math.max(
    1,
    Math.min(6, body.includeSprints ?? DEFAULT_SPRINTS),
  );

  const sprints = await deps.selectRecords<SprintRecord>("sprints", {
    goal_id: `eq.${goal.id}`,
    order: "sprint_number.desc",
    limit: includeSprints,
  });

  const sprintIds = sprints.map((sprint) => sprint.id);

  const tasks = sprintIds.length
    ? await deps.selectRecords<SprintTaskRecord>("sprint_tasks", {
      sprint_id: `in.(${sprintIds.join(",")})`,
    })
    : [];

  const tasksBySprint = new Map<string, SprintTaskRecord[]>();
  for (const task of tasks) {
    if (!tasksBySprint.has(task.sprint_id)) {
      tasksBySprint.set(task.sprint_id, []);
    }
    tasksBySprint.get(task.sprint_id)?.push(task);
  }

  const sprintSummaries: SprintSummary[] = sprints.map((sprint) => ({
    sprint,
    ...summarizeTaskStatuses(tasksBySprint.get(sprint.id) ?? []),
  }));

  const progressLogs = await deps.selectRecords<ProgressLogRecord>(
    "progress_logs",
    {
      goal_id: `eq.${goal.id}`,
      recorded_at: [
        `gte.${sinceDate.toISOString()}`,
        `lte.${untilDate.toISOString()}`,
      ],
      order: "recorded_at.desc",
      limit: 30,
    },
  );

  const insights = await deps.generateGrowthReport(
    goalRecordToGoalInput(goal),
    sprintSummaries,
    progressLogs,
  );

  return {
    goal,
    sprintSummaries,
    insights,
    progressLogs,
  };
}
