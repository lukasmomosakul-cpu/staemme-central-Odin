-- 020 (27.09.2026): Einladungscodes ohne Ablauf. gueltig_stunden 0/NULL ->
-- gueltig_bis NULL. Einmalig bleibt der Code trotzdem.
alter table public.team_einladungen alter column gueltig_bis drop not null;

create or replace function public.einladung_erstellen(rolle text, gueltig_stunden integer default 48)
returns table (id uuid, code text, gueltig_bis timestamptz)
language plpgsql security definer set search_path = public
as $$
declare
  t uuid; r text; c text; bis timestamptz;
begin
  if rolle not in ('Admin','Player','Observer') then raise exception 'Ungültige Rolle'; end if;
  select m.team_id, m.role into t, r from public.team_members m where m.user_id = auth.uid() limit 1;
  if t is null then raise exception 'Kein Team'; end if;
  if r not in ('Owner','Admin') then raise exception 'Nur Owner oder Admin dürfen einladen'; end if;
  -- 020: 0 oder leer = laeuft nie ab (gueltig_bis NULL). Einmalig bleibt der Code trotzdem.
  if gueltig_stunden is null or gueltig_stunden <= 0 then
    bis := null;
  else
    bis := now() + make_interval(hours => least(gueltig_stunden, 720));
  end if;
  loop
    c := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    exit when not exists (select 1 from public.team_einladungen e where e.code = c);
  end loop;
  return query
    insert into public.team_einladungen (team_id, code, rolle, erstellt_von, gueltig_bis)
    values (t, c, einladung_erstellen.rolle, auth.uid(), bis)
    returning team_einladungen.id, team_einladungen.code, team_einladungen.gueltig_bis;
end;
$$;
grant execute on function public.einladung_erstellen(text, integer) to authenticated;

create or replace function public.einladung_einloesen(code text, konten_mitnehmen boolean default true)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  e public.team_einladungen%rowtype;
  alt_team uuid; alt_rolle text; alt_rest integer; konten integer := 0; skripte integer := 0;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  select * into e from public.team_einladungen x
   where x.code = upper(trim(einladung_einloesen.code)) for update;
  if not found then raise exception 'Code unbekannt'; end if;
  if e.zurueckgezogen_at is not null then raise exception 'Code wurde zurückgezogen'; end if;
  if e.eingeloest_at is not null then raise exception 'Code wurde bereits eingelöst'; end if;
  if e.gueltig_bis is not null and e.gueltig_bis < now() then raise exception 'Code ist abgelaufen'; end if;
  if exists (select 1 from public.team_members m where m.team_id = e.team_id and m.user_id = auth.uid()) then
    raise exception 'Du bist bereits Mitglied dieses Teams';
  end if;

  select m.team_id, m.role into alt_team, alt_rolle from public.team_members m where m.user_id = auth.uid() limit 1;

  if alt_team is not null then
    select count(*) into alt_rest from public.team_members m where m.team_id = alt_team and m.user_id <> auth.uid();
    -- Ein Team ohne Owner waere unverwaltbar.
    if alt_rolle = 'Owner' and alt_rest > 0 then
      raise exception 'Du bist Owner deines bisherigen Teams mit weiteren Mitgliedern - erst die Owner-Rolle abgeben';
    end if;
    if konten_mitnehmen then
      if alt_rolle not in ('Owner','Admin') then
        raise exception 'Spielkonten mitnehmen darf nur Owner oder Admin des bisherigen Teams';
      end if;
      delete from public.member_account_permissions p
       using public.game_accounts a where a.id = p.account_id and a.team_id = alt_team;
      update public.godbot_settings  set team_id = e.team_id where team_id = alt_team;
      update public.godbot_befehle   set team_id = e.team_id where team_id = alt_team;
      update public.account_leases   set team_id = e.team_id where team_id = alt_team;
      update public.app_events       set team_id = e.team_id where team_id = alt_team and account_id is not null;
      update public.notifications    set team_id = e.team_id where team_id = alt_team and account_id is not null;
      update public.game_accounts    set team_id = e.team_id where team_id = alt_team;
      get diagnostics konten = row_count;
      -- Skripte nur, wenn das alte Team danach leer ist - sonst gehoeren sie
      -- den Verbleibenden.
      if alt_rest = 0 then
        update public.scripts set team_id = e.team_id where team_id = alt_team;
        get diagnostics skripte = row_count;
      end if;
    end if;
    delete from public.team_members m where m.team_id = alt_team and m.user_id = auth.uid();
  end if;

  insert into public.team_members (team_id, user_id, role) values (e.team_id, auth.uid(), e.rolle);
  update public.team_einladungen x set eingeloest_von = auth.uid(), eingeloest_at = now() where x.id = e.id;

  return jsonb_build_object('team_id', e.team_id, 'rolle', e.rolle,
    'konten_mitgenommen', konten, 'skripte_mitgenommen', skripte, 'altes_team', alt_team);
end;
$$;
grant execute on function public.einladung_einloesen(text, boolean) to authenticated;
