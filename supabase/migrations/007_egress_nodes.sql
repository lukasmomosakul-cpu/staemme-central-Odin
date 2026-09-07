-- Egress-Gateways: serverseitige Zuordnung von Network Profiles zu festen Gateway-Endpunkten.
-- Keine Proxy-Secrets oder Spielpasswörter in dieser Tabelle speichern.

create table if not exists public.egress_nodes (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  network_profile_id uuid references public.network_profiles(id) on delete set null,
  name text not null,
  endpoint_url text not null,
  public_ip inet,
  status text not null default 'offline' check (status in ('online', 'offline', 'degraded')),
  last_seen_at timestamptz,
  provider text,
  created_at timestamptz not null default now(),
  unique(team_id, name)
);

create index if not exists egress_nodes_team_id_idx on public.egress_nodes(team_id);
create index if not exists egress_nodes_network_profile_id_idx on public.egress_nodes(network_profile_id);

alter table public.egress_nodes enable row level security;

create policy "team members can view egress nodes"
on public.egress_nodes
for select
to authenticated
using (
  exists (
    select 1 from public.team_members tm
    where tm.team_id = egress_nodes.team_id
      and tm.user_id = auth.uid()
  )
);

create policy "team admins can insert egress nodes"
on public.egress_nodes
for insert
to authenticated
with check (
  exists (
    select 1 from public.team_members tm
    where tm.team_id = egress_nodes.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);

create policy "team admins can update egress nodes"
on public.egress_nodes
for update
to authenticated
using (
  exists (
    select 1 from public.team_members tm
    where tm.team_id = egress_nodes.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
)
with check (
  exists (
    select 1 from public.team_members tm
    where tm.team_id = egress_nodes.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);

create policy "team admins can delete egress nodes"
on public.egress_nodes
for delete
to authenticated
using (
  exists (
    select 1 from public.team_members tm
    where tm.team_id = egress_nodes.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);
