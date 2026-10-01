-- 023 (01.10.2026): Indizes (Supabase-Performancepruefung).
create index if not exists app_events_konto_zeit on public.app_events (account_id, created_at desc);
create index if not exists godbot_settings_team on public.godbot_settings (team_id);
create index if not exists game_accounts_team on public.game_accounts (team_id);
drop index if exists public.team_members_team_user_uidx;
