-- 029 (Odin 2.0.19 / Odin PC 564.3, 05.10.2026)
-- IP-Pruefung in der Datenbank: "zwei Konten mit ANDEREM Namen ueber
-- dieselbe IP auf DERSELBEN Welt" wird atomar geprueft und die IP im
-- selben Schritt an die Geraete-Sperre geschrieben. Ein Advisory-Lock je
-- IP serialisiert alle Pruefungen dieser IP (auch teamuebergreifend), damit
-- zwei Geraete, die gleichzeitig starten, sich gegenseitig sehen.
--
-- Ablauf beim Client: lease_holen -> lease_ip_pruefen -> erst dann laden.
-- Im Betrieb: App alle 10 Min, Odin PC jede Minute.

alter table public.account_leases
  add column if not exists ip_konflikt_at timestamptz;

-- "de256", "DE256 ", "256" -> "de256"; leer bleibt leer.
create or replace function public.odin_welt_norm(p text)
returns text language sql immutable as $$
  select case
    when x ~ '^[0-9]+$' then 'de' || x
    else x end
  from (select lower(regexp_replace(coalesce(p, ''), '[^a-zA-Z0-9]', '', 'g')) as x) s
$$;

create or replace function public.lease_ip_pruefen(p_account uuid, p_geraet text, p_ip text)
returns table(ok boolean, art text, konflikt text)
language plpgsql security definer set search_path to 'public' as $$
declare
  v_team uuid; v_name text; v_welt text;
  v_halter text;
  r record;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;

  select a.team_id, lower(trim(coalesce(a.name, ''))), public.odin_welt_norm(a.world)
    into v_team, v_name, v_welt
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

  -- Aktive Sperren (in den letzten 10 Min gemeldet) mit derselben IP.
  -- Anderer Name + gleiche Welt (oder eine Welt unbekannt) = Konflikt.
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
    -- Eigene IP aus der Sperre nehmen, damit das andere Konto nicht
    -- seinerseits durch dieses gesperrte Konto blockiert wird.
    update public.account_leases l set ip = null, ip_at = now(), ip_konflikt_at = now()
     where l.account_id = p_account and l.geraet_id = p_geraet;
    return query select false, 'konflikt'::text,
      ('IP ' || p_ip || ' nutzt bereits ' ||
       case when r.team_id = v_team then 'Konto „' || coalesce(r.anzeige, '?') || '“'
            else 'ein Konto eines anderen Teams' end ||
       ' auf ' || case when r.welt = '' then 'unbekannter Welt' else r.welt end ||
       ' - zwei Konten über dieselbe IP auf derselben Welt sind gesperrt')::text;
    return;
  end if;

  update public.account_leases l set ip = p_ip, ip_at = now(), ip_konflikt_at = null
   where l.account_id = p_account and l.geraet_id = p_geraet;
  return query select true, 'ok'::text, null::text;
end $$;

revoke all on function public.lease_ip_pruefen(uuid, text, text) from public, anon;
grant execute on function public.lease_ip_pruefen(uuid, text, text) to authenticated;

-- Geraetewechsel einer Sperre: die IP des alten Geraets gilt nicht mehr.
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
        ip_konflikt_at = case when l.geraet_id = excluded.geraet_id then l.ip_konflikt_at else null end
    where l.geraet_id = excluded.geraet_id
       or l.gemeldet < now() - make_interval(secs => p_frist_s)
       or p_erzwingen;

  return query
    select l.geraet_id, l.geraet_name, l.gemeldet, (l.geraet_id = p_geraet)
    from public.account_leases l where l.account_id = p_account;
end $$;

-- Alte Clients (bis App 2.0.18 / PC 564.2) melden die Geraete-IP ungeprueft.
-- Ab 029 fuellt das nur noch leere IPs und nie die eines Kontos, das wegen
-- eines IP-Konflikts angehalten ist. Neue Clients rufen es nicht mehr auf.
create or replace function public.lease_ip_melden(p_geraet text, p_ip text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;
  update public.account_leases l set ip = p_ip, ip_at = now()
   where l.geraet_id = p_geraet and public.is_team_member(l.team_id)
     and l.ip is null and l.ip_konflikt_at is null
     and not exists (select 1 from public.game_accounts g
                      where g.id::text = l.account_id::text and coalesce(trim(g.proxy),'') <> '');
  get diagnostics n = row_count;
  return n;
end;
$$;
