-- 013: Benachrichtigungen zwischen allen Geraeten eines Teams, ohne Discord-Umweg
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  account_id uuid references public.game_accounts(id) on delete cascade,
  level text not null default 'info',
  title text not null,
  body text not null default '',
  source text not null default '',
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create index if not exists notifications_team_time_idx on public.notifications (team_id, created_at desc);
alter table public.notifications enable row level security;
create policy "members can read notifications" on public.notifications
  for select to authenticated using (is_team_member(team_id));
create policy "members can insert notifications" on public.notifications
  for insert to authenticated with check (is_team_member(team_id));
create policy "managers can delete notifications" on public.notifications
  for delete to authenticated using (is_team_manager(team_id));
create or replace function public.prune_notifications()
returns void language sql security definer set search_path = public as $$
  delete from public.notifications where created_at < now() - interval '7 days';
$$;
