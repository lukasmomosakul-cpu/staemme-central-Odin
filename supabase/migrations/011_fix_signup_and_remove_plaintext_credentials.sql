-- 011: Signup-Bootstrap reparieren + Klartext-Zugangsdaten entfernen
--
-- Problem 1: bootstrap_first_team_owner() legte die Mitgliedschaft nur an,
--   wenn noch GAR KEIN Team existierte. Sobald ein Team da war, bekam jeder
--   neue Nutzer keine Mitgliedschaft -> Login erfolgreich, App leer.
-- Problem 2: teams/team_members hatten nur SELECT-Policies, also konnte
--   sich auch niemand selbst eines anlegen.
-- Problem 3: game_accounts.login_password war Klartext und teamweit lesbar.

create unique index if not exists team_members_team_user_uidx
  on public.team_members (team_id, user_id);

create or replace function public.is_team_member(target_team uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.team_members
                where team_id = target_team and user_id = auth.uid());
$$;

create or replace function public.is_team_manager(target_team uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.team_members
                where team_id = target_team and user_id = auth.uid()
                  and role in ('Owner','Admin'));
$$;

-- Jeder neue Nutzer bekommt ein EIGENES Team (bei offener Registrierung
-- duerfen Fremde nicht automatisch in ein bestehendes Team rutschen).
create or replace function public.bootstrap_first_team_owner()
returns trigger language plpgsql security definer set search_path = public as $$
declare new_team uuid;
begin
  insert into public.teams (name)
    values ('Team ' || coalesce(nullif(new.email, ''), new.id::text))
    returning id into new_team;
  insert into public.team_members (team_id, user_id, role)
    values (new_team, new.id, 'Owner')
    on conflict (team_id, user_id) do nothing;
  return new;
end; $$;

drop policy if exists "owner can update team" on public.teams;
create policy "owner can update team" on public.teams
  for update to authenticated
  using (is_team_manager(id)) with check (is_team_manager(id));

drop policy if exists "owner can delete team" on public.teams;
create policy "owner can delete team" on public.teams
  for delete to authenticated using (is_team_manager(id));

drop policy if exists "managers can insert members" on public.team_members;
create policy "managers can insert members" on public.team_members
  for insert to authenticated with check (is_team_manager(team_id));

drop policy if exists "managers can update members" on public.team_members;
create policy "managers can update members" on public.team_members
  for update to authenticated
  using (is_team_manager(team_id)) with check (is_team_manager(team_id));

drop policy if exists "managers can delete members" on public.team_members;
create policy "managers can delete members" on public.team_members
  for delete to authenticated using (is_team_manager(team_id));

alter table public.game_accounts drop column if exists login_password;
drop table if exists public.game_account_credentials;
