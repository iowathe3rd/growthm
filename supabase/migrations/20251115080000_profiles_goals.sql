-- name: create-profiles-goals
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key default auth.uid(),
  display_name text not null,
  email text not null unique,
  timezone text default 'UTC',
  onboarding_complete boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add constraint profiles_auth_user_fk
    foreign key (id)
    references auth.users (id)
    on delete cascade;

create index if not exists profiles_created_idx on public.profiles (created_at desc);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text not null,
  horizon_months integer not null check (horizon_months > 0 and horizon_months <= 60),
  daily_minutes integer not null check (daily_minutes > 0 and daily_minutes <= 1440),
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  priority integer not null default 0,
  target_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists goals_user_idx on public.goals (user_id);
create index if not exists goals_status_idx on public.goals (status);
