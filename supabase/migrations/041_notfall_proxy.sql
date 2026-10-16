-- 2.0.80 (16.10.2026): Notfall-IP. Eine Proxy-Vorlage je Team mit dem
-- Platzhalter {sitzung}; der Notfall-Knopf setzt daraus game_accounts.proxy
-- mit einer zufaelligen Sitzung "nf...". Die App prueft und wuerfelt neu.
create table if not exists public.notfall_proxy (
  team_id uuid primary key references public.teams(id) on delete cascade,
  vorlage text not null,
  updated_at timestamptz not null default now()
);
alter table public.notfall_proxy enable row level security;
drop policy if exists "members read notfall_proxy" on public.notfall_proxy;
drop policy if exists "members write notfall_proxy" on public.notfall_proxy;
create policy "members read notfall_proxy" on public.notfall_proxy for select using (public.is_team_member(team_id));
create policy "members write notfall_proxy" on public.notfall_proxy for all using (public.is_team_member(team_id)) with check (public.is_team_member(team_id));
