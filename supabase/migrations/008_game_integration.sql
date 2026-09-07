-- Read-only game integration foundation.
-- No game passwords are stored here. A short-lived per-account token will be added
-- when the Tampermonkey bridge is implemented.
create table if not exists public.game_integrations (
  id uuid primary key default gen_random_uuid(),
  game_account_id uuid not null references public.game_accounts(id) on delete cascade,
  world text not null,
  status text not null default 'disconnected' check (status in ('disconnected','connected','error')),
  last_seen_at timestamptz,
  last_page text,
  player_name text,
  village_count integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(game_account_id)
);

alter table public.game_integrations enable row level security;

create policy "team members can read game integrations"
on public.game_integrations for select
using (
  exists (
    select 1 from public.game_accounts ga
    join public.team_members tm on tm.team_id = ga.team_id
    where ga.id = game_integrations.game_account_id
      and tm.user_id = auth.uid()
  )
);

create policy "team managers can manage game integrations"
on public.game_integrations for all
using (
  exists (
    select 1 from public.game_accounts ga
    join public.team_members tm on tm.team_id = ga.team_id
    where ga.id = game_integrations.game_account_id
      and tm.user_id = auth.uid()
      and tm.role in ('Owner','Admin')
  )
)
with check (
  exists (
    select 1 from public.game_accounts ga
    join public.team_members tm on tm.team_id = ga.team_id
    where ga.id = game_integrations.game_account_id
      and tm.user_id = auth.uid()
      and tm.role in ('Owner','Admin')
  )
);
