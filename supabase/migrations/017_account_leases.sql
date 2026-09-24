-- 017: Geraete-Sperre je Spielkonto ("Lease").
--
-- Laufen zwei Geraete mit GodBot fuer DASSELBE Konto, gehen doppelte
-- Anfragen an den Spielserver (zwei Raubzuege, zwei Farmlaeufe, zwei
-- Rohstoffverteilungen) - genau das Muster, das der Botschutz bestraft.
-- Diese Tabelle haelt fest, welches Geraet die Automatik eines Kontos
-- gerade fuehrt. Ein Geraet haelt die Sperre, solange es sich mindestens
-- alle p_frist_s Sekunden meldet; danach darf ein anderes sie nehmen.

create table if not exists public.account_leases (
  account_id   uuid primary key references public.game_accounts(id) on delete cascade,
  team_id      uuid not null references public.teams(id) on delete cascade,
  geraet_id    text not null,
  geraet_name  text not null default '',
  seit         timestamptz not null default now(),
  gemeldet     timestamptz not null default now()
);

alter table public.account_leases enable row level security;

drop policy if exists "members can read leases" on public.account_leases;
create policy "members can read leases" on public.account_leases
  for select using (public.is_team_member(team_id));
-- Schreiben nur ueber die beiden Funktionen unten (atomar).

-- Nehmen oder verlaengern. Gibt immer den aktuellen Halter zurueck;
-- "erhalten" sagt, ob es das aufrufende Geraet ist.
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
        gemeldet    = now()
    where l.geraet_id = excluded.geraet_id
       or l.gemeldet < now() - make_interval(secs => p_frist_s)
       or p_erzwingen;

  return query
    select l.geraet_id, l.geraet_name, l.gemeldet, (l.geraet_id = p_geraet)
    from public.account_leases l where l.account_id = p_account;
end $$;

create or replace function public.lease_freigeben(p_account uuid, p_geraet text)
returns boolean
language plpgsql security definer set search_path to 'public' as $$
declare v_team uuid; n integer;
begin
  select a.team_id into v_team from public.game_accounts a where a.id = p_account;
  if v_team is null or not public.is_team_member(v_team) then return false; end if;
  delete from public.account_leases where account_id = p_account and geraet_id = p_geraet;
  get diagnostics n = row_count;
  return n > 0;
end $$;

grant execute on function public.lease_holen(uuid, text, text, boolean, integer) to authenticated;
grant execute on function public.lease_freigeben(uuid, text) to authenticated;
