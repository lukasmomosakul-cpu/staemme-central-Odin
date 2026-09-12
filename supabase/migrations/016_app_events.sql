-- 016: Geraeteuebergreifendes Protokoll
-- Fehlerhafte Vorgaenge sollen in Odin sichtbar sein, nicht nur auf dem Geraet,
-- auf dem sie aufgetreten sind.
create table if not exists public.app_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  account_id uuid references public.game_accounts(id) on delete set null,
  level text not null default 'info',
  bereich text not null default 'app',
  message text not null,
  device text not null default '',
  app_version text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists app_events_team_time_idx on public.app_events (team_id, created_at desc);
create index if not exists app_events_level_idx on public.app_events (team_id, level, created_at desc);
alter table public.app_events enable row level security;
create policy "members can read app events" on public.app_events
  for select to authenticated using (is_team_member(team_id));
create policy "members can insert app events" on public.app_events
  for insert to authenticated with check (is_team_member(team_id));
create policy "managers can delete app events" on public.app_events
  for delete to authenticated using (is_team_manager(team_id));
create or replace function public.prune_app_events()
returns void language sql security definer set search_path = public as $$
  delete from public.app_events where created_at < now() - interval '14 days';
$$;
