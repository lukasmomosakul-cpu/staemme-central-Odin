-- 018: Befehle aus der App an GodBot (Steuerzentrale)
-- Einzelne Einstellung je Zeile statt ganzer Block: ein Befehl aendert genau
-- ein Feld und kann nie einen aelteren Stand ueber einen neueren legen.
-- Abgeholt vom Bootstrap der Spielansicht (OdinNative.befehleHolen), erledigt
-- ueber godbot_befehl_erledigt (HttpURLConnection kennt kein PATCH).
create table if not exists public.godbot_befehle (
  id bigint generated always as identity primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  account_id uuid not null references public.game_accounts(id) on delete cascade,
  pfad text not null,
  wert jsonb,
  erstellt_at timestamptz not null default now(),
  erstellt_von uuid references auth.users(id) default auth.uid(),
  erledigt_at timestamptz,
  ok boolean,
  ergebnis text
);
create index if not exists godbot_befehle_offen_idx
  on public.godbot_befehle (account_id, id) where erledigt_at is null;
alter table public.godbot_befehle enable row level security;
drop policy if exists "members read befehle" on public.godbot_befehle;
create policy "members read befehle" on public.godbot_befehle
  for select to authenticated using (is_team_member(team_id));
drop policy if exists "members insert befehle" on public.godbot_befehle;
create policy "members insert befehle" on public.godbot_befehle
  for insert to authenticated with check (is_team_member(team_id));
drop policy if exists "members update befehle" on public.godbot_befehle;
create policy "members update befehle" on public.godbot_befehle
  for update to authenticated using (is_team_member(team_id)) with check (is_team_member(team_id));

create or replace function public.godbot_befehl_erledigt(p_id bigint, p_ok boolean, p_ergebnis text)
returns void language sql security invoker set search_path = public as $$
  update public.godbot_befehle
     set erledigt_at = now(), ok = p_ok, ergebnis = left(coalesce(p_ergebnis, ''), 300)
   where id = p_id and erledigt_at is null;
$$;
grant execute on function public.godbot_befehl_erledigt(bigint, boolean, text) to authenticated;
