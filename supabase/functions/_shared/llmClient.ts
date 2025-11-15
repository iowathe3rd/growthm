import type {
  Difficulty,
  GoalInput,
  GoalRecord,
  ProgressLogRecord,
  SkillTreeDraft,
  SkillTreeNodeDraft,
  SprintPlan,
  SprintSummary,
  SprintTaskDraft,
} from "./types.ts";

const CHAT_URL = "https://api.openai.com/v1/chat/completions";
const MODEL = "gpt-4.1";
const MS_PER_DAY = 24 * 60 * 60 * 1000;

async function callLLM(prompt: string): Promise<string> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured for LLM calls");
  }

  const response = await fetch(CHAT_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        {
          role: "system",
          content:
            "You are a growth architect for a personal development product.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`LLM call failed with ${response.status}: ${text}`);
  }

  const payload = await response.json();
  const choice = payload?.choices?.[0]?.message?.content;
  if (!choice) {
    throw new Error("LLM response did not contain a completion");
  }

  return choice;
}

function formatNodeValue(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(
    /^-+|-+$/g,
    "",
  );
}

function buildFallbackNodes(input: GoalInput): SkillTreeNodeDraft[] {
  const base = formatNodeValue(input.title);
  const focus = Math.max(3, Math.round(input.horizonMonths * 4));
  const nodes: SkillTreeNodeDraft[] = [
    {
      nodePath: `${base}.clarify`,
      title: `Clarify the vision for ${input.title}`,
      level: 1,
      focusHours: focus,
      payload: { example: "define success criteria" },
    },
    {
      nodePath: `${base}.practices`,
      title: "Build foundational practice habits",
      level: 1,
      focusHours: Math.max(2, Math.round(focus * 0.8)),
      payload: { example: "daily review, spaced repetition" },
    },
    {
      nodePath: `${base}.feedback`,
      title: "Capture signals and feedback",
      level: 2,
      focusHours: Math.max(1, Math.round(focus * 0.6)),
      payload: { example: "weekly reflection" },
    },
  ];
  return nodes;
}

function heuristicSprintSummary(input: GoalInput): string {
  return `Sprint 1 for "${input.title}" focuses on clarifying intent and kickstarting practice.`;
}

function buildSprintTasks(
  nodes: SkillTreeNodeDraft[],
  baseDate: Date,
): SprintTaskDraft[] {
  return nodes.slice(0, 4).map((node, index) => {
    const due = new Date(baseDate);
    due.setDate(baseDate.getDate() + index * 2 + 3);
    const difficulty: Difficulty = node.focusHours > 20
      ? "high"
      : node.focusHours > 10
      ? "medium"
      : "low";
    return {
      title: node.title,
      description: `Work on ${node.title} by allocating ${
        Math.ceil(node.focusHours)
      } focused minutes this week.`,
      difficulty,
      dueDate: due.toISOString().split("T")[0],
      estimatedMinutes: Math.max(15, Math.round(node.focusHours)),
      nodePath: node.nodePath,
    };
  });
}

function buildTreeJson(
  input: GoalInput,
  nodes: SkillTreeNodeDraft[],
): Record<string, unknown> {
  return {
    title: input.title,
    description: input.description,
    horizonMonths: input.horizonMonths,
    createdBy: "system",
    nodes: nodes.map((node) => ({
      path: node.nodePath,
      title: node.title,
      level: node.level,
      focusHours: node.focusHours,
      payload: node.payload,
    })),
  };
}

export async function generateSkillTreeDraft(
  input: GoalInput,
): Promise<SkillTreeDraft> {
  const nodes = buildFallbackNodes(input);

  if (Deno.env.get("OPENAI_API_KEY")) {
    try {
      const prompt =
        `Create 3 skill-tree nodes for the goal titled "${input.title}". Output valid JSON like {"nodes": [{"nodePath":"...","title":"...","level":1,"focusHours":10,"payload":{}}]}.`;
      const raw = await callLLM(prompt);
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed.nodes) && parsed.nodes.length > 0) {
        return {
          treeJson: buildTreeJson(input, parsed.nodes),
          nodes: parsed.nodes,
        };
      }
    } catch (error) {
      console.warn("LLM fallback used because:", error);
    }
  }

  return {
    treeJson: buildTreeJson(input, nodes),
    nodes,
  };
}

function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

export function planInitialSprint(
  input: GoalInput,
  nodes: SkillTreeNodeDraft[],
  startDate = new Date(),
  lengthDays = 6,
): SprintPlan {
  const from = new Date(startDate);
  const to = new Date(from);
  to.setDate(from.getDate() + lengthDays);

  return {
    sprintNumber: 1,
    fromDate: formatDate(from),
    toDate: formatDate(to),
    summary: heuristicSprintSummary(input),
    tasks: buildSprintTasks(nodes, from),
  };
}

export function goalRecordToGoalInput(goal: GoalRecord): GoalInput {
  return {
    title: goal.title,
    description: goal.description,
    horizonMonths: goal.horizon_months,
    dailyMinutes: goal.daily_minutes,
  };
}

function formatSprintPrompt(
  goal: GoalInput,
  nodes: SkillTreeNodeDraft[],
  sprintNumber: number,
  fromDate: Date,
  toDate: Date,
  context: {
    completed: number;
    pending: number;
    skipped: number;
    feedback?: string;
    feelingTags?: string[];
  },
): string {
  const nodeList = nodes.slice(0, 5).map((node) =>
    `* ${node.nodePath}: ${node.title}`
  ).join("\n");
  const summary = context.feedback
    ? `Based on feedback: ${context.feedback}`
    : "";
  const feelings = context.feelingTags?.length
    ? `Feelings: ${context.feelingTags.join(", ")}`
    : "";
  return `Goal: ${goal.title}\nDescription: ${goal.description}\nSprint #: ${sprintNumber}, window ${
    formatDate(fromDate)
  } -> ${
    formatDate(toDate)
  }\nContext: completed ${context.completed}, pending ${context.pending}, skipped ${context.skipped}. ${summary} ${feelings}\nCandidate nodes:\n${nodeList}\nOutput JSON: {\"summary\": \"...\", \"tasks\": [{\"title\":\"...\",\"description\":\"...\",\"difficulty\":\"low|medium|high\",\"nodePath\":\"...\",\"estimatedMinutes\": 15,\"dueDate\": \"YYYY-MM-DD\"}]}\nUse at most 5 tasks.`;
}

function normalizeLLMTask(
  task: Record<string, unknown>,
  defaultDate: Date,
  index: number,
): SprintTaskDraft {
  const baseDue = new Date(defaultDate);
  baseDue.setDate(baseDue.getDate() + index * 2 + 3);
  const dueDate = typeof task.dueDate === "string" && task.dueDate.length > 0
    ? task.dueDate
    : formatDate(baseDue);
  const difficulty = typeof task.difficulty === "string" &&
      ["low", "medium", "high"].includes(task.difficulty)
    ? (task.difficulty as Difficulty)
    : "medium";
  return {
    title: typeof task.title === "string" ? task.title : "Task",
    description: typeof task.description === "string"
      ? task.description
      : "Allocate focused time to this node.",
    difficulty,
    dueDate,
    estimatedMinutes: typeof task.estimatedMinutes === "number"
      ? task.estimatedMinutes
      : 30,
    nodePath: typeof task.nodePath === "string" ? task.nodePath : undefined,
  };
}

export async function planAdaptiveSprint(
  goal: GoalInput,
  nodes: SkillTreeNodeDraft[],
  sprintNumber: number,
  fromDate: Date,
  toDate: Date,
  context: {
    completed: number;
    pending: number;
    skipped: number;
    feedback?: string;
    feelingTags?: string[];
  },
): Promise<SprintPlan> {
  const lengthDays = Math.max(
    1,
    Math.round((toDate.getTime() - fromDate.getTime()) / MS_PER_DAY),
  );
  const fallback = planInitialSprint(goal, nodes, fromDate, lengthDays);
  fallback.sprintNumber = sprintNumber;
  fallback.fromDate = formatDate(fromDate);
  fallback.toDate = formatDate(toDate);
  fallback.summary = context.feedback ?? fallback.summary;

  if (Deno.env.get("OPENAI_API_KEY")) {
    try {
      const prompt = formatSprintPrompt(
        goal,
        nodes,
        sprintNumber,
        fromDate,
        toDate,
        context,
      );
      const raw = await callLLM(prompt);
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed.tasks) && parsed.tasks.length > 0) {
        return {
          sprintNumber,
          fromDate: formatDate(fromDate),
          toDate: formatDate(toDate),
          summary: typeof parsed.summary === "string"
            ? parsed.summary
            : fallback.summary,
          tasks: parsed.tasks.map((
            task: Record<string, unknown>,
            index: number,
          ) => normalizeLLMTask(task, fromDate, index)),
        };
      }
    } catch (error) {
      console.warn("generate sprint plan fallback", error);
    }
  }

  return fallback;
}

function buildGrowthReportPrompt(
  goal: GoalInput,
  summaries: SprintSummary[],
  logs: ProgressLogRecord[],
): string {
  const sprintLines = summaries.map((summary) =>
    `Sprint ${summary.sprint.sprint_number}: ${summary.completed} done, ${summary.pending} pending, ${summary.skipped} skipped, summary ${
      summary.sprint.summary ?? ""
    }`
  ).join("\n");
  const logLines = logs
    .slice(0, 5)
    .map((log) => `Log ${log.recorded_at}: ${JSON.stringify(log.payload)}`)
    .join("\n");
  return `You are a growth analyst. Goal: ${goal.title}.\nSprints:\n${sprintLines}\nLogs:\n${logLines}\nOutput JSON {"narrative":"...","recommendations":["...","..."]}`;
}

export async function generateGrowthReport(
  goal: GoalInput,
  summaries: SprintSummary[],
  logs: ProgressLogRecord[],
): Promise<{ narrative: string; recommendations: string[] }> {
  const totalCompleted = summaries.reduce(
    (acc, summary) => acc + summary.completed,
    0,
  );
  const fallback = {
    narrative:
      `Across ${summaries.length} sprints you completed ${totalCompleted} tasks and have ${
        summaries.reduce((acc, summary) => acc + summary.pending, 0)
      } pending items. Continue tracking streaks and reflections.`,
    recommendations: [
      "Review the most skipped nodes and adjust your focus.",
      "Keep annotating progress logs so adaptation stays grounded in data.",
    ],
  };

  if (!Deno.env.get("OPENAI_API_KEY")) {
    return fallback;
  }

  try {
    const prompt = buildGrowthReportPrompt(goal, summaries, logs);
    const raw = await callLLM(prompt);
    const parsed = JSON.parse(raw);
    if (
      typeof parsed.narrative === "string" &&
      Array.isArray(parsed.recommendations)
    ) {
      return {
        narrative: parsed.narrative,
        recommendations: parsed.recommendations.filter((item: unknown) =>
          typeof item === "string"
        ) as string[],
      };
    }
  } catch (error) {
    console.warn("Growth report fallback", error);
  }

  return fallback;
}
