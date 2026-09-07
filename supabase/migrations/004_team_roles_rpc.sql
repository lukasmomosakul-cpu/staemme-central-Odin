-- Teamzentrale Odin: secure team-member lookup and role management.
-- Run this once in the Supabase SQL Editor.

create or replace function public.get_team_members(target_team uuid)
returns table (
  id uuid,
  user_id uuid,
  role text,
  email text,
  display_name text
)
language sql
stable
security definer
set search_path = public
as $$
  select m.id, m.user_id, m.role, u.email, coalesce(u.raw_user_meta_data->>'display_name', u.raw_user_meta_data->>'name')
  from public.team_members m
  join auth.users u on u.id = m.user_id
  where m.team_id = target_team
    and public.is_team_member(target_team)
  order by m.created_at asc;
$$;

grant execute on function public.get_team_members(uuid) to authenticated;

create or replace function public.set_team_member_role(target_member uuid, new_role text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_team uuid;
  actor_role text;
begin
  if new_role not in ('Admin','Player','Observer') then
    raise exception 'Ungültige Rolle';
  end if;

  select team_id into target_team from public.team_members where id = target_member;
  if target_team is null then raise exception 'Mitglied nicht gefunden'; end if;

  select role into actor_role from public.team_members where team_id = target_team and user_id = auth.uid();
  if actor_role not in ('Owner','Admin') then raise exception 'Keine Berechtigung'; end if;

  update public.team_members set role = new_role where id = target_member and role <> 'Owner';
  return true;
end;
$$;

grant execute on function public.set_team_member_role(uuid, text) to authenticated;

-- Only owners/admins may change account permissions. Reads remain available to team members.
drop policy if exists "managers can insert permissions" on public.member_account_permissions;
drop policy if exists "managers can delete permissions" on public.member_account_permissions;

create policy "managers can insert permissions" on public.member_account_permissions
for insert
with check (
  exists (
    select 1
    from public.team_members actor
    join public.team_members target on target.id = member_account_permissions.member_id and target.team_id = actor.team_id
    join public.game_accounts account on account.id = member_account_permissions.account_id and account.team_id = actor.team_id
    where actor.user_id = auth.uid() and actor.role in ('Owner','Admin') and target.role = 'Player'
  )
);

create policy "managers can delete permissions" on public.member_account_permissions
for delete
using (
  exists (
    select 1
    from public.team_members actor
    join public.team_members target on target.id = member_account_permissions.member_id and target.team_id = actor.team_id
    join public.game_accounts account on account.id = member_account_permissions.account_id and account.team_id = actor.team_id
    where actor.user_id = auth.uid() and actor.role in ('Owner','Admin') and target.role = 'Player'
  )
);
