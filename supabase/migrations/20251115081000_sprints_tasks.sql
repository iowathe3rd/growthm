-- name: create-sprints-tasks

create table if not exists public.sprints (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade,
  sprint_number integer not null check (sprint_number > 0),
  from_date date not null,
  to_date date not null,
  status text not null default 'planned' check (status in ('planned','in_progress','completed','cancelled')),
  summary text,
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(goal_id, sprint_number)
);

create table if not exists public.sprint_tasks (
  id uuid primary key default gen_random_uuid(),
  sprint_id uuid not null references public.sprints (id) on delete cascade,
  skill_node_id uuid references public.skill_tree_nodes (id),
  title text not null,
  description text not null,
  difficulty text not null check (difficulty in ('low','medium','high')),
  status text not null default 'pending' check (status in ('pending','done','skipped')),
  due_date date,
  estimated_minutes integer check (estimated_minutes > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists sprint_tasks_sprint_idx on public.sprint_tasks (sprint_id);
