-- name: create-skill-trees

create table if not exists public.skill_trees (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade unique,
  tree_json jsonb not null,
  generated_by text not null default 'system',
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.skill_tree_nodes (
  id uuid primary key default gen_random_uuid(),
  skill_tree_id uuid not null references public.skill_trees (id) on delete cascade,
  node_path text not null,
  title text not null,
  level integer not null default 1,
  focus_hours integer not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (skill_tree_id, node_path)
);

create index if not exists skill_tree_nodes_tree_idx on public.skill_tree_nodes (skill_tree_id);
