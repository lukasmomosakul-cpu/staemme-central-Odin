-- 021 (01.10.2026): Ablage fuer GodBot-Protokoll, Seitenquellen und
-- Anfrage-Mitschnitte (bisher nur auf dem Geraet / per Diagnosepaket).
create table if not exists public.godbot_ablage (
  id bigserial primary key,
  team_id uuid not null references public.teams(id) on delete cascade,
  account_id uuid not null references public.game_accounts(id) on delete cascade,
  art text not null check (art in ('protokoll','seite','mitschnitt')),
  titel text,
  inhalt text not null,
  geraet text,
  erstellt_at timestamptz not null default now()
);
create index if not exists godbot_ablage_konto_zeit on public.godbot_ablage (account_id, art, erstellt_at desc);
alter table public.godbot_ablage enable row level security;
drop policy if exists "team liest ablage" on public.godbot_ablage;
create policy "team liest ablage" on public.godbot_ablage for select using (public.is_team_member(team_id));

create or replace function public.ablage_schreiben(p_account uuid, p_art text, p_titel text, p_inhalt text, p_geraet text default null)
returns boolean
language plpgsql security definer set search_path = public
as $$
declare t uuid;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  select a.team_id into t from public.game_accounts a where a.id = p_account;
  if t is null or not public.is_team_member(t) then raise exception 'Kein Zugriff auf dieses Konto'; end if;
  if p_art not in ('protokoll','seite','mitschnitt') then raise exception 'Unbekannte Art'; end if;
  insert into public.godbot_ablage (team_id, account_id, art, titel, inhalt, geraet)
  values (t, p_account, p_art, left(p_titel, 500), left(p_inhalt, 1500000), left(p_geraet, 100));
  if random() < 0.05 then
    delete from public.godbot_ablage where account_id = p_account and (
      (art in ('protokoll','mitschnitt') and erstellt_at < now() - interval '14 days') or
      (art = 'seite' and erstellt_at < now() - interval '60 days'));
  end if;
  return true;
end;
$$;
grant execute on function public.ablage_schreiben(uuid, text, text, text, text) to authenticated;
