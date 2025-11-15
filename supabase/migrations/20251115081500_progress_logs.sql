-- name: create-progress-logs

create table if not exists public.progress_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  goal_id uuid not null references public.goals (id) on delete cascade,
  sprint_id uuid references public.sprints (id) on delete cascade,
  payload jsonb not null,
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists progress_logs_user_goal_idx on public.progress_logs (user_id, goal_id);
create index if not exists progress_logs_sprint_idx on public.progress_logs (sprint_id);
