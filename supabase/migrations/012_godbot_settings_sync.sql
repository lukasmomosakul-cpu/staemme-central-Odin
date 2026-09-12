-- 012: Geraeteuebergreifender Abgleich der GodBot-Einstellungen
-- Ersetzt den Ingame-Notizblock als Transportweg (dort ~44.000 von 60.000
-- erlaubten Zeichen belegt, rund die Haelfte durch tw_build_templates_deleted).
create table if not exists public.godbot_settings (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  account_id uuid not null references public.game_accounts(id) on delete cascade,
  skey text not null,
  value text not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  unique (account_id, skey)
);
create index if not exists godbot_settings_account_idx on public.godbot_settings (account_id);
alter table public.godbot_settings enable row level security;
create policy "members can read godbot settings" on public.godbot_settings
  for select to authenticated using (is_team_member(team_id));
create policy "members can insert godbot settings" on public.godbot_settings
  for insert to authenticated with check (is_team_member(team_id));
create policy "members can update godbot settings" on public.godbot_settings
  for update to authenticated using (is_team_member(team_id)) with check (is_team_member(team_id));
create policy "members can delete godbot settings" on public.godbot_settings
  for delete to authenticated using (is_team_member(team_id));
create or replace function public.touch_godbot_settings()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists godbot_settings_touch on public.godbot_settings;
create trigger godbot_settings_touch before update on public.godbot_settings
  for each row execute function public.touch_godbot_settings();
