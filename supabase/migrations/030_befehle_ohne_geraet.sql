-- 030 (Odin 2.0.20, 05.10.2026)
-- 1) Botschutz eines anderen Geraets: nach botschutz_team_min Minuten ohne
--    Entwarnung meldet sich jedes Geraet im Team.
-- 2) Abschickplaene (Angriffsplaner: Angriffe/Fakes/Unterstuetzungen,
--    Rausstellen-Zyklen, Massenunterstuetzung): befehle_vorlauf_min Minuten
--    vorher eine Meldung, wenn KEIN Geraet das Konto gerade fuehrt (keine
--    Geraete-Sperre in den letzten 3 Min gemeldet).

alter table public.notification_settings
  add column if not exists botschutz_team_min integer not null default 3,
  add column if not exists befehle_warnung_an boolean not null default true,
  add column if not exists befehle_vorlauf_min integer not null default 3;

-- Text -> jsonb ohne Abbruch bei kaputtem Inhalt.
create or replace function public.odin_jsonb(t text)
returns jsonb language plpgsql immutable as $$
begin
  if t is null or t !~ '^\s*[\{\[]' then return null; end if;
  return t::jsonb;
exception when others then return null;
end $$;

-- Zahl (ms) aus jsonb-Wert/Text, sonst null.
create or replace function public.odin_ms(t text)
returns bigint language sql immutable as $$
  select case when t ~ '^\s*"?[0-9]+(\.[0-9]+)?"?\s*$'
              then floor(replace(trim(t), '"', '')::numeric)::bigint end
$$;

create or replace function public.befehle_ohne_geraet(p_team uuid, p_vorlauf_s integer default 180)
returns table(account_id uuid, konto text, welt text, art text, befehl_id text,
              starts_at_ms bigint, von text, nach text)
language plpgsql stable security definer set search_path to 'public' as $$
declare v_jetzt bigint := floor(extract(epoch from now()) * 1000)::bigint;
        v_bis bigint;
begin
  if auth.uid() is null or not public.is_team_member(p_team) then
    raise exception 'kein Zugriff';
  end if;
  v_bis := v_jetzt + greatest(30, least(3600, coalesce(p_vorlauf_s, 180)))::bigint * 1000;
  return query
  with konten as (
    select g.id, g.name, g.world from public.game_accounts g
     where g.team_id = p_team
       and not exists (select 1 from public.account_leases l
                        where l.account_id = g.id and l.gemeldet >= now() - interval '3 minutes')
  ),
  ap as (   -- Angriffsplaner
    select k.id, k.name, k.world, a.value as b
      from konten k
      join public.godbot_settings s on s.account_id = k.id and s.skey = 'tw_attack_plans'
      cross join lateral jsonb_each(coalesce(public.odin_jsonb(s.value), '{}'::jsonb)) p
      cross join lateral jsonb_array_elements(case when jsonb_typeof(p.value->'attacks') = 'array'
                                                   then p.value->'attacks' else '[]'::jsonb end) a
     where jsonb_typeof(coalesce(public.odin_jsonb(s.value), '{}'::jsonb)) = 'object'
       and jsonb_typeof(p.value) = 'object'
  ),
  tb as (   -- Rausstellen
    select k.id, k.name, k.world, c.value as b
      from konten k
      join public.godbot_settings s on s.account_id = k.id and s.skey = 'tw_tabben_plan'
      cross join lateral jsonb_array_elements(case when jsonb_typeof(public.odin_jsonb(s.value)->'cycles') = 'array'
                                                   then public.odin_jsonb(s.value)->'cycles' else '[]'::jsonb end) c
  )
  select ap.id, ap.name, ap.world,
         case when ap.b->>'type' = 'support' then 'Unterstützung'
              when ap.b->>'fake' = 'true' then 'Fake'
              when coalesce(public.odin_ms(ap.b->'troops'->>'snob'), 0) > 0 then 'AG-Angriff'
              else 'Angriff' end,
         coalesce(ap.b->>'id', ''), public.odin_ms(ap.b->>'startsAtMs'),
         coalesce(ap.b->>'fromCoord', ''), coalesce(ap.b->>'toCoord', '')
    from ap
   where coalesce(ap.b->>'sent', 'false') <> 'true'
     and coalesce(ap.b->>'failed', 'false') <> 'true'
     and coalesce(ap.b->>'removed', 'false') <> 'true'
     and public.odin_ms(ap.b->>'startsAtMs') between v_jetzt and v_bis
  union all
  select tb.id, tb.name, tb.world, 'Rausstellen',
         coalesce(tb.b->>'id', 'tab-' || (tb.b->>'sendAtMs')), public.odin_ms(tb.b->>'sendAtMs'),
         coalesce(tb.b->>'originCoord', tb.b->>'originVillageId', ''), coalesce(tb.b->>'parkCoord', '')
    from tb
   where coalesce(tb.b->>'sent', 'false') <> 'true'
     and coalesce(tb.b->>'failed', 'false') <> 'true'
     and public.odin_ms(tb.b->>'sendAtMs') between v_jetzt and v_bis
  union all
  select k.id, k.name, k.world, 'Massenunterstützung', 'ms-' || public.odin_ms(s.value),
         public.odin_ms(s.value), '', ''
    from konten k
    join public.godbot_settings s on s.account_id = k.id and s.skey = 'tw_mass_support_next_at'
   where public.odin_ms(s.value) between v_jetzt and v_bis
  order by 6;
end $$;

revoke all on function public.befehle_ohne_geraet(uuid, integer) from public, anon;
grant execute on function public.befehle_ohne_geraet(uuid, integer) to authenticated;
