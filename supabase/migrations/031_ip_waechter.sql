-- 031 (Odin 2.0.22 / Odin PC 564.5, 08.10.2026)
-- IP-Waechter: letzter Pruefstand je Geraete-Sperre, damit Dashboard und
-- Protokoll zeigen, WELCHES Konto WANN mit WELCHER IP geprueft wurde, auf
-- welchem Weg (Proxy/direkt) und ob WebRTC dicht ist.

alter table public.account_leases
  add column if not exists ip_pruef_at timestamptz,
  add column if not exists ip_befund text,
  add column if not exists ip_weg text,
  add column if not exists rtc_befund text,
  add column if not exists rtc_at timestamptz;

create or replace function public.lease_ip_pruefen(p_account uuid, p_geraet text, p_ip text)
returns table(ok boolean, art text, konflikt text)
language plpgsql security definer set search_path to 'public' as $$
declare
  v_team uuid; v_name text; v_welt text; v_weg text;
  v_halter text;
  r record;
  v_text text;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;
  select a.team_id, lower(trim(coalesce(a.name, ''))), public.odin_welt_norm(a.world),
         case when coalesce(trim(a.proxy), '') <> '' then 'proxy' else 'direkt' end
    into v_team, v_name, v_welt, v_weg
    from public.game_accounts a where a.id = p_account;
  if v_team is null or not public.is_team_member(v_team) then
    raise exception 'kein Zugriff auf dieses Konto';
  end if;
  perform pg_advisory_xact_lock(hashtext('odin_ip:' || p_ip));
  select l.geraet_id into v_halter from public.account_leases l where l.account_id = p_account;
  if v_halter is null or v_halter <> p_geraet then
    return query select false, 'keine_sperre'::text, 'Geräte-Sperre liegt nicht bei diesem Gerät'::text;
    return;
  end if;
  select l.account_id, l.team_id, lower(trim(coalesce(g.name, ''))) as name,
         public.odin_welt_norm(g.world) as welt, g.name as anzeige
    into r
    from public.account_leases l
    join public.game_accounts g on g.id = l.account_id
   where l.ip = p_ip
     and l.account_id <> p_account
     and l.gemeldet >= now() - interval '10 minutes'
     and lower(trim(coalesce(g.name, ''))) <> v_name
     and (v_welt = '' or public.odin_welt_norm(g.world) = '' or public.odin_welt_norm(g.world) = v_welt)
   limit 1;
  if found then
    v_text := 'IP ' || p_ip || ' nutzt bereits ' ||
       case when r.team_id = v_team then 'Konto „' || coalesce(r.anzeige, '?') || '“'
            else 'ein Konto eines anderen Teams' end ||
       ' auf ' || case when r.welt = '' then 'unbekannter Welt' else r.welt end ||
       ' - zwei Konten über dieselbe IP auf derselben Welt sind gesperrt';
    update public.account_leases l
       set ip = null, ip_at = now(), ip_konflikt_at = now(),
           ip_pruef_at = now(), ip_befund = v_text, ip_weg = v_weg
     where l.account_id = p_account and l.geraet_id = p_geraet;
    return query select false, 'konflikt'::text, v_text;
    return;
  end if;
  update public.account_leases l
     set ip = p_ip, ip_at = now(), ip_konflikt_at = null,
         ip_pruef_at = now(), ip_befund = 'ok', ip_weg = v_weg
   where l.account_id = p_account and l.geraet_id = p_geraet;
  return query select true, 'ok'::text, null::text;
end $$;

-- Ergebnis der WebRTC-Pruefung (App: Gegenprobe des Schutzes; PC: Test im
-- Browser). Nur fuer die eigene Sperre.
create or replace function public.lease_rtc_melden(p_account uuid, p_geraet text, p_befund text)
returns integer language plpgsql security definer set search_path to 'public' as $$
declare v_team uuid; n integer;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  select a.team_id into v_team from public.game_accounts a where a.id = p_account;
  if v_team is null or not public.is_team_member(v_team) then
    raise exception 'kein Zugriff auf dieses Konto';
  end if;
  update public.account_leases l
     set rtc_befund = left(coalesce(p_befund, ''), 300), rtc_at = now()
   where l.account_id = p_account and l.geraet_id = p_geraet;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.lease_rtc_melden(uuid, text, text) from public, anon;
grant execute on function public.lease_rtc_melden(uuid, text, text) to authenticated;

-- Geraetewechsel: auch den Pruefstand des alten Geraets verwerfen.
create or replace function public.lease_holen(
  p_account uuid, p_geraet text, p_name text,
  p_erzwingen boolean default false, p_frist_s integer default 180)
returns table(geraet_id text, geraet_name text, gemeldet timestamptz, erhalten boolean)
language plpgsql security definer set search_path to 'public' as $$
#variable_conflict use_column
declare v_team uuid;
begin
  select a.team_id into v_team from public.game_accounts a where a.id = p_account;
  if v_team is null or not public.is_team_member(v_team) then
    raise exception 'kein Zugriff auf dieses Konto';
  end if;
  insert into public.account_leases as l (account_id, team_id, geraet_id, geraet_name, seit, gemeldet)
  values (p_account, v_team, p_geraet, coalesce(p_name,''), now(), now())
  on conflict (account_id) do update
    set geraet_id   = excluded.geraet_id,
        geraet_name = excluded.geraet_name,
        seit        = case when l.geraet_id = excluded.geraet_id then l.seit else now() end,
        gemeldet    = now(),
        ip          = case when l.geraet_id = excluded.geraet_id then l.ip else null end,
        ip_at       = case when l.geraet_id = excluded.geraet_id then l.ip_at else null end,
        ip_konflikt_at = case when l.geraet_id = excluded.geraet_id then l.ip_konflikt_at else null end,
        ip_pruef_at = case when l.geraet_id = excluded.geraet_id then l.ip_pruef_at else null end,
        ip_befund   = case when l.geraet_id = excluded.geraet_id then l.ip_befund else null end,
        ip_weg      = case when l.geraet_id = excluded.geraet_id then l.ip_weg else null end,
        rtc_befund  = case when l.geraet_id = excluded.geraet_id then l.rtc_befund else null end,
        rtc_at      = case when l.geraet_id = excluded.geraet_id then l.rtc_at else null end
    where l.geraet_id = excluded.geraet_id
       or l.gemeldet < now() - make_interval(secs => p_frist_s)
       or p_erzwingen;
  return query
    select l.geraet_id, l.geraet_name, l.gemeldet, (l.geraet_id = p_geraet)
    from public.account_leases l where l.account_id = p_account;
end $$;
