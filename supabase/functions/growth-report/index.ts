import { serve } from "https://deno.land/std@0.214.0/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";
import { ApiError, errorHandler } from "../_shared/errorHandler.ts";
import {
  extractBearerToken,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import {
  generateGrowthReport,
  goalRecordToGoalInput,
} from "../_shared/llmClient.ts";
import { summarizeTaskStatuses } from "../_shared/sprintStats.ts";
import type {
  GrowthReportBody,
  GrowthReportResult,
  ProgressLogRecord,
  SprintSummary,
  SprintTaskRecord,
} from "../_shared/types.ts";

const DEFAULT_SPRINTS = 3;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(null, { status: 405, headers: { Allow: "POST" } });
    }

    const token = extractBearerToken(req);
    const user = await requireAuthenticatedUser(token);

    const body = (await req.json()) as GrowthReportBody;
    if (!body.goalId?.trim()) {
      throw new ApiError("goalId is required", 400);
    }

    const { data: goal, error: goalError } = await supabaseAdmin
      .from("goals")
      .select("*")
      .eq("id", body.goalId)
      .maybeSingle();

    if (goalError || !goal) {
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

    const { data: sprints } = await supabaseAdmin
      .from("sprints")
      .select("*")
      .eq("goal_id", goal.id)
      .order("sprint_number", { ascending: false })
      .limit(includeSprints);

    const sprintIds = (sprints ?? []).map((sprint) => sprint.id);
    const { data: tasks } = sprintIds.length
      ? await supabaseAdmin
        .from("sprint_tasks")
        .select("*")
        .in("sprint_id", sprintIds)
      : { data: [] };

    const tasksBySprint = new Map<string, SprintTaskRecord[]>();
    (tasks ?? []).forEach((task) => {
      if (!tasksBySprint.has(task.sprint_id)) {
        tasksBySprint.set(task.sprint_id, []);
      }
      tasksBySprint.get(task.sprint_id)?.push(task);
    });

    const sprintSummaries: SprintSummary[] = (sprints ?? []).map((sprint) => ({
      sprint,
      ...summarizeTaskStatuses(tasksBySprint.get(sprint.id) ?? []),
    }));

    const { data: progressLogs } = await supabaseAdmin
      .from("progress_logs")
      .select("*")
      .eq("goal_id", goal.id)
      .gte("recorded_at", sinceDate.toISOString())
      .lte("recorded_at", untilDate.toISOString())
      .order("recorded_at", { ascending: false })
      .limit(30);

    const insights = await generateGrowthReport(
      goalRecordToGoalInput(goal),
      sprintSummaries,
      (progressLogs ?? []) as ProgressLogRecord[],
    );

    const response: GrowthReportResult = {
      goal,
      sprintSummaries,
      insights,
      progressLogs: (progressLogs ?? []) as ProgressLogRecord[],
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return errorHandler(error);
  }
});

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
