-- 028: Freischaltung statt Einladungscode (04.10.2026)
-- Es gibt EIN Hauptteam (teams.haupt). Jeder neue Odin-Nutzer bekommt wie
-- bisher zunaechst ein eigenes Team (Trigger bootstrap_first_team_owner) und
-- gilt als "wartet auf Freischaltung". Owner/Admin des Hauptteams schalten ihn
-- per Klick frei: er wird Mitglied des Hauptteams, seine Spielkonten samt
-- GodBot-Daten wandern mit, das leere Einzelteam wird geloescht.

alter table public.teams add column if not exists haupt boolean not null default false;
update public.teams set haupt = true where id = '660a969d-fb52-49ca-b853-38fccf7f194c';
create unique index if not exists teams_ein_hauptteam on public.teams (haupt) where haupt;

-- Wer ein Spielkonto eingebracht hat (fuer die Anzeige im Team).
alter table public.game_accounts add column if not exists besitzer uuid references auth.users(id) on delete set null;
alter table public.game_accounts alter column besitzer set default auth.uid();
update public.game_accounts a set besitzer = m.user_id
  from public.team_members m
 where a.besitzer is null and m.team_id = a.team_id and m.role = 'Owner';

create or replace function public.hauptteam_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from public.teams where haupt limit 1;
$$;
grant execute on function public.hauptteam_id() to authenticated;

-- Liste fuer Owner/Admin des Hauptteams: alle Odin-Nutzer, die (noch) nicht
-- Mitglied des Hauptteams sind, mit ihren Spielkonten.
create or replace function public.freigabe_liste()
returns table (user_id uuid, email text, registriert timestamptz, konten jsonb)
language plpgsql stable security definer set search_path = public, auth as $$
declare h uuid := public.hauptteam_id();
begin
  if h is null or not public.is_team_manager(h) then
    raise exception 'Nur Owner oder Admin des Hauptteams';
  end if;
  return query
    select u.id, u.email::text, u.created_at,
           coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'name', a.name, 'world', a.world) order by a.world)
                       from public.team_members m join public.game_accounts a on a.team_id = m.team_id
                      where m.user_id = u.id
                        and (a.besitzer = u.id or not exists (
                              select 1 from public.team_members o where o.team_id = m.team_id and o.user_id <> u.id))),
                    '[]'::jsonb)
      from auth.users u
     where not exists (select 1 from public.team_members x where x.team_id = h and x.user_id = u.id)
     order by u.created_at;
end; $$;
revoke all on function public.freigabe_liste() from public;
grant execute on function public.freigabe_liste() to authenticated;

create or replace function public.nutzer_freischalten(p_user uuid, p_rolle text default 'Player')
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  h uuid := public.hauptteam_id();
  alt record; rest integer; ids uuid[]; konten integer := 0; n integer;
begin
  if h is null or not public.is_team_manager(h) then raise exception 'Nur Owner oder Admin des Hauptteams'; end if;
  if p_rolle not in ('Admin', 'Player', 'Observer') then raise exception 'Ungültige Rolle'; end if;
  if not exists (select 1 from auth.users where id = p_user) then raise exception 'Nutzer unbekannt'; end if;
  if exists (select 1 from public.team_members where team_id = h and user_id = p_user) then
    raise exception 'Bereits freigeschaltet';
  end if;

  for alt in select m.team_id from public.team_members m where m.user_id = p_user and m.team_id <> h loop
    select count(*) into rest from public.team_members where team_id = alt.team_id and user_id <> p_user;
    -- Allein im Team: alles mitnehmen. Sonst nur die selbst eingebrachten Konten.
    select coalesce(array_agg(id), '{}') into ids from public.game_accounts
     where team_id = alt.team_id and (rest = 0 or besitzer = p_user);
    if array_length(ids, 1) > 0 then
      delete from public.member_account_permissions where account_id = any(ids);
      update public.godbot_settings set team_id = h where account_id = any(ids);
      update public.godbot_befehle  set team_id = h where account_id = any(ids);
      update public.account_leases  set team_id = h where account_id = any(ids);
      update public.app_events      set team_id = h where account_id = any(ids);
      update public.notifications   set team_id = h where account_id = any(ids);
      update public.godbot_ablage   set team_id = h where account_id = any(ids);
      -- Proxy-Profile, auf die die Konten zeigen, gehoeren mit ins Team.
      update public.egress_profiles e set team_id = h
       where e.team_id = alt.team_id and e.id in (select egress_profile_id from public.game_accounts where id = any(ids));
      update public.game_accounts set team_id = h, besitzer = coalesce(besitzer, p_user) where id = any(ids);
      get diagnostics n = row_count; konten := konten + n;
    end if;
    if rest = 0 then
      update public.scripts set team_id = h where team_id = alt.team_id;
      update public.bau_vorlagen v set team_id = h
       where v.team_id = alt.team_id
         and not exists (select 1 from public.bau_vorlagen w where w.team_id = h and lower(w.name) = lower(v.name));
      delete from public.teams where id = alt.team_id;   -- Rest (Mitgliedschaft, Einladungen ...) faellt mit
    else
      delete from public.team_members where team_id = alt.team_id and user_id = p_user;
    end if;
  end loop;

  insert into public.team_members (team_id, user_id, role) values (h, p_user, p_rolle);
  return jsonb_build_object('team_id', h, 'rolle', p_rolle, 'konten', konten);
end; $$;
revoke all on function public.nutzer_freischalten(uuid, text) from public;
grant execute on function public.nutzer_freischalten(uuid, text) to authenticated;
