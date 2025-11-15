export type Difficulty = "low" | "medium" | "high";
export type TaskStatus = "pending" | "done" | "skipped";

export interface GoalInput {
  title: string;
  description: string;
  horizonMonths: number;
  dailyMinutes: number;
  tags?: string[];
}

export interface CreateGrowthMapBody extends GoalInput {
  targetDate?: string;
}

export interface SkillTreeNodeDraft {
  nodePath: string;
  title: string;
  level: number;
  focusHours: number;
  payload: Record<string, unknown>;
}

export interface SkillTreeDraft {
  treeJson: Record<string, unknown>;
  nodes: SkillTreeNodeDraft[];
}

export interface SprintTaskDraft {
  title: string;
  description: string;
  difficulty: Difficulty;
  dueDate?: string;
  estimatedMinutes?: number;
  nodePath?: string;
}

export interface SprintPlan {
  sprintNumber: number;
  fromDate: string;
  toDate: string;
  summary: string;
  tasks: SprintTaskDraft[];
}

export interface GoalRecord {
  id: string;
  user_id: string;
  title: string;
  description: string;
  horizon_months: number;
  daily_minutes: number;
  status: string;
  priority: number;
  target_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface SkillTreeRecord {
  id: string;
  goal_id: string;
  tree_json: Record<string, unknown>;
  generated_by: string;
  version: number;
  created_at: string;
  updated_at: string;
}

export interface SkillTreeNodeRecord {
  id: string;
  skill_tree_id: string;
  node_path: string;
  title: string;
  level: number;
  focus_hours: number;
  payload: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SprintRecord {
  id: string;
  goal_id: string;
  sprint_number: number;
  from_date: string;
  to_date: string;
  status: string;
  summary: string | null;
  metrics: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SprintTaskRecord {
  id: string;
  sprint_id: string;
  skill_node_id: string | null;
  title: string;
  description: string;
  difficulty: Difficulty;
  status: TaskStatus;
  due_date: string | null;
  estimated_minutes: number | null;
  created_at: string;
  updated_at: string;
}

export interface TaskStatusUpdate {
  taskId: string;
  status: TaskStatus;
  notes?: string;
}

export interface RegenerateSprintBody {
  sprintId: string;
  statusUpdates?: TaskStatusUpdate[];
  feedback?: string;
  feelingTags?: string[];
}

export interface RegenerateSprintResult {
  sprint: SprintRecord & { tasks: SprintTaskRecord[] };
  progressLog: ProgressLogRecord;
}

export interface GrowthReportBody {
  goalId: string;
  since?: string;
  until?: string;
  includeSprints?: number;
}

export interface GrowthReportResult {
  goal: GoalRecord;
  sprintSummaries: SprintSummary[];
  insights: {
    narrative: string;
    recommendations: string[];
  };
  progressLogs: ProgressLogRecord[];
}

export interface SprintSummary {
  sprint: SprintRecord;
  completed: number;
  pending: number;
  skipped: number;
}

export interface ProgressLogRecord {
  id: string;
  user_id: string;
  goal_id: string;
  sprint_id: string | null;
  payload: Record<string, unknown>;
  recorded_at: string;
  created_at: string;
}

export interface CreateGrowthMapResult {
  goal: GoalRecord;
  skillTree: SkillTreeRecord & { nodes: SkillTreeNodeRecord[] };
  sprint: SprintRecord & { tasks: SprintTaskRecord[] };
}

export interface GoalDetailResponse {
  goal: GoalRecord;
  skillTree:
    | SkillTreeRecord & {
      nodes: SkillTreeNodeRecord[];
    }
    | null;
  latestSprint:
    | (SprintRecord & {
      tasks: SprintTaskRecord[];
    })
    | null;
}
