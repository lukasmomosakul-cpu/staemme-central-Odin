-- 027: Vorlagensammlung (Bauvorlagen fuer alle Konten)
-- team_id NULL = fuer alle Odin-Nutzer sichtbar (gemeinsame Sammlung),
-- sonst nur fuer das Team. Aendern/Loeschen: Team-Mitglieder bzw. bei
-- gemeinsamen Vorlagen nur, wer sie angelegt hat.
-- queue: GodBot-Format "gebaeude:stufen;..." (relative Stufen ab 0).
-- Uebertragen an ein Konto als godbot_befehle-Zeile pfad=bauvorlage.uebernehmen.
create table if not exists public.bau_vorlagen (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  beschreibung text not null default '',
  welt text,
  queue text not null check (queue ~ '^[a-z_]+:[0-9]{1,2}(;[a-z_]+:[0-9]{1,2})*$'),
  erstellt_von uuid references auth.users(id) default auth.uid(),
  erstellt_at timestamptz not null default now(),
  geaendert_at timestamptz not null default now()
);
create unique index if not exists bau_vorlagen_name_idx
  on public.bau_vorlagen (coalesce(team_id, '00000000-0000-0000-0000-000000000000'::uuid), lower(name));
alter table public.bau_vorlagen enable row level security;

drop policy if exists "vorlagen lesen" on public.bau_vorlagen;
create policy "vorlagen lesen" on public.bau_vorlagen
  for select to authenticated using (team_id is null or is_team_member(team_id));
drop policy if exists "vorlagen anlegen" on public.bau_vorlagen;
create policy "vorlagen anlegen" on public.bau_vorlagen
  for insert to authenticated with check (
    (team_id is null and erstellt_von = auth.uid()) or (team_id is not null and is_team_member(team_id)));
drop policy if exists "vorlagen aendern" on public.bau_vorlagen;
create policy "vorlagen aendern" on public.bau_vorlagen
  for update to authenticated
  using ((team_id is null and erstellt_von = auth.uid()) or (team_id is not null and is_team_member(team_id)))
  with check ((team_id is null and erstellt_von = auth.uid()) or (team_id is not null and is_team_member(team_id)));
drop policy if exists "vorlagen loeschen" on public.bau_vorlagen;
create policy "vorlagen loeschen" on public.bau_vorlagen
  for delete to authenticated
  using ((team_id is null and erstellt_von = auth.uid()) or (team_id is not null and is_team_member(team_id)));

create or replace function public.bau_vorlagen_geaendert() returns trigger
language plpgsql set search_path = public as $$
begin new.geaendert_at := now(); return new; end; $$;
drop trigger if exists bau_vorlagen_geaendert on public.bau_vorlagen;
create trigger bau_vorlagen_geaendert before update on public.bau_vorlagen
  for each row execute function public.bau_vorlagen_geaendert();

grant select, insert, update, delete on public.bau_vorlagen to authenticated;

-- Startinhalt: LKav-Rush W260 (Plan v2, 04.10.2026), gemeinsam fuer alle.
insert into public.bau_vorlagen (team_id, name, beschreibung, welt, queue, erstellt_von)
select null, 'LKav-Rush W260',
  'Mit Ausbau-Belohnungen optimiert (150/150/100 je Stufe). Sim.: Stall 1 ~32 h, 10 LKav bezahlt ~39 h. '
  || 'Eisen 1-9 zuerst, Belohnungs-Füllstufen (BH, Speicher, Versteck, Markt, Wall). Nach Kaserne 2 sofort 1 Speer '
  || 'rekrutieren (Quest: +10 Speer/+10 Schwert). Nach Stall 1 LKav in der Schmiede erforschen (von Hand). '
  || 'Endstufen: HG 15, Rohstoffe 15, Kaserne 5, Schmiede 5, Stall 10, Hof 12, Speicher 10, Wall 5, Markt 3, Versteck 2. '
  || 'Ohne Belohnungssystem auf der Welt NICHT verwenden (dann langsamer als der klassische Plan).',
  'de260',
  'main:1;farm:1;storage:1;iron:4;wood:1;iron:2;stone:1;iron:2;wood:1;iron:1;wood:1;stone:1;wood:1;stone:1;wood:4;stone:1;main:1;stone:1;main:1;stone:2;main:1;farm:1;storage:2;barracks:1;market:1;hide:1;main:4;storage:1;hide:1;main:2;smith:1;wall:1;smith:1;barracks:1;farm:1;smith:1;storage:1;barracks:3;smith:1;wall:1;smith:1;stable:1;wall:1;farm:2;storage:1;iron:1;stable:2;wood:2;stone:3;farm:2;wall:2;market:2;storage:2;iron:3;stable:2;main:3;wood:3;stone:3;farm:3;storage:2;iron:2;main:2;wood:2;stone:2;farm:2;stable:5',
  '55c5751b-5489-4b92-b249-a21cbce640ea'
where not exists (select 1 from public.bau_vorlagen where team_id is null and lower(name) = lower('LKav-Rush W260'));
