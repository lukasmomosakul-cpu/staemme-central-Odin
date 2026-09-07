-- Teamzentrale Odin: persistent data model
-- Run this once in the Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Teamzentrale Odin',
  created_at timestamptz not null default now()
);

create table if not exists public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'Player' check (role in ('Owner','Admin','Player','Observer')),
  created_at timestamptz not null default now(),
  unique(team_id, user_id)
);

create table if not exists public.network_profiles (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  provider_type text not null default 'egress',
  public_ip text,
  status text not null default 'Offline',
  created_at timestamptz not null default now()
);

create table if not exists public.game_accounts (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  name text not null,
  world text not null,
  player_name text,
  network_profile_id uuid references public.network_profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.member_account_permissions (
  member_id uuid not null references public.team_members(id) on delete cascade,
  account_id uuid not null references public.game_accounts(id) on delete cascade,
  primary key(member_id, account_id)
);

alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.network_profiles enable row level security;
alter table public.game_accounts enable row level security;
alter table public.member_account_permissions enable row level security;

create or replace function public.is_team_member(target_team uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.team_members where team_id = target_team and user_id = auth.uid());
$$;

create policy "members can read their teams" on public.teams for select using (public.is_team_member(id));
create policy "members can read team members" on public.team_members for select using (public.is_team_member(team_id));
create policy "members can read accounts" on public.game_accounts for select using (public.is_team_member(team_id));
create policy "members can read network profiles" on public.network_profiles for select using (public.is_team_member(team_id));
create policy "members can read permissions" on public.member_account_permissions for select using (
  exists(select 1 from public.team_members m join public.game_accounts a on a.team_id = m.team_id where m.id = member_account_permissions.member_id and a.id = member_account_permissions.account_id and m.user_id = auth.uid())
);
