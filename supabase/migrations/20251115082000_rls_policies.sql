-- name: add-security-policies

alter table public.profiles enable row level security;
create policy if not exists "Profiles: manage own record" on public.profiles
  for all
  using (id = auth.uid())
  with check (id = auth.uid());

alter table public.goals enable row level security;
create policy if not exists "Goals: own user read" on public.goals
  for select
  using (user_id = auth.uid());
create policy if not exists "Goals: own user write" on public.goals
  for insert, update, delete
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

alter table public.skill_trees enable row level security;
create policy if not exists "Skill trees: owner goals" on public.skill_trees
  for all
  using (
    exists (
      select 1 from public.goals g
      where g.id = public.skill_trees.goal_id
        and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.goals g
      where g.id = public.skill_trees.goal_id
        and g.user_id = auth.uid()
    )
  );

alter table public.skill_tree_nodes enable row level security;
create policy if not exists "Skill nodes: owner goal" on public.skill_tree_nodes
  for all
  using (
    exists (
      select 1 from public.skill_trees st
      join public.goals g on g.id = st.goal_id
      where st.id = public.skill_tree_nodes.skill_tree_id
        and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.skill_trees st
      join public.goals g on g.id = st.goal_id
      where st.id = public.skill_tree_nodes.skill_tree_id
        and g.user_id = auth.uid()
    )
  );

alter table public.sprints enable row level security;
create policy if not exists "Sprints: owner goal" on public.sprints
  for all
  using (
    exists (
      select 1 from public.goals g
      where g.id = public.sprints.goal_id
        and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.goals g
      where g.id = public.sprints.goal_id
        and g.user_id = auth.uid()
    )
  );

alter table public.sprint_tasks enable row level security;
create policy if not exists "Sprint tasks: owner sprint" on public.sprint_tasks
  for all
  using (
    exists (
      select 1 from public.sprints s
      join public.goals g on g.id = s.goal_id
      where s.id = public.sprint_tasks.sprint_id
        and g.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.sprints s
      join public.goals g on g.id = s.goal_id
      where s.id = public.sprint_tasks.sprint_id
        and g.user_id = auth.uid()
    )
  );

alter table public.progress_logs enable row level security;
create policy if not exists "Progress logs: owner" on public.progress_logs
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
