-- 025: Account-basierte Egress-Profile.
-- Ein Profil gehoert zum logischen Die-Staemme-Account und kann von
-- mehreren Welt-Eintraegen desselben Accounts geteilt werden (z.B. FetterOrk).
create table if not exists public.egress_profiles (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  endpoint_url text,
  public_ip inet,
  provider text,
  status text not null default 'offline' check (status in ('online','offline','degraded')),
  enabled boolean not null default false,
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  unique(team_id, name)
);

alter table public.game_accounts
  add column if not exists egress_profile_id uuid
  references public.egress_profiles(id) on delete set null;

create index if not exists egress_profiles_team_id_idx
  on public.egress_profiles(team_id);
create index if not exists game_accounts_egress_profile_id_idx
  on public.game_accounts(egress_profile_id);

alter table public.egress_profiles enable row level security;

create policy "team members can view egress profiles"
on public.egress_profiles for select to authenticated
using (exists (
  select 1 from public.team_members tm
  where tm.team_id = egress_profiles.team_id
    and tm.user_id = auth.uid()
));

create policy "team admins can insert egress profiles"
on public.egress_profiles for insert to authenticated
with check (exists (
  select 1 from public.team_members tm
  where tm.team_id = egress_profiles.team_id
    and tm.user_id = auth.uid()
    and lower(tm.role) in ('owner','admin')
));

create policy "team admins can update egress profiles"
on public.egress_profiles for update to authenticated
using (exists (
  select 1 from public.team_members tm
  where tm.team_id = egress_profiles.team_id
    and tm.user_id = auth.uid()
    and lower(tm.role) in ('owner','admin')
))
with check (exists (
  select 1 from public.team_members tm
  where tm.team_id = egress_profiles.team_id
    and tm.user_id = auth.uid()
    and lower(tm.role) in ('owner','admin')
));

create policy "team admins can delete egress profiles"
on public.egress_profiles for delete to authenticated
using (exists (
  select 1 from public.team_members tm
  where tm.team_id = egress_profiles.team_id
    and tm.user_id = auth.uid()
    and lower(tm.role) in ('owner','admin')
));