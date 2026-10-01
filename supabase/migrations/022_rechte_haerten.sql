-- 022 (01.10.2026): Rechte haerten (Supabase-Sicherheitspruefung).
-- SECURITY-DEFINER-Funktionen, die eine Anmeldung voraussetzen, sind nicht
-- mehr anonym aufrufbar; Wartungs- und Triggerfunktionen gar nicht ueber
-- die API. Offen bleiben bewusst: is_team_member/is_team_manager (RLS) und
-- ingest_game_telemetry (tokengeschuetzter Eingang).
alter function public.touch_godbot_settings() set search_path = public;
revoke execute on function public.ablage_schreiben(uuid, text, text, text, text) from public, anon;
revoke execute on function public.create_game_bridge(uuid, text) from public, anon;
revoke execute on function public.einladung_einloesen(text, boolean) from public, anon;
revoke execute on function public.einladung_erstellen(text, integer) from public, anon;
revoke execute on function public.einladung_zurueckziehen(uuid) from public, anon;
revoke execute on function public.get_team_members(uuid) from public, anon;
revoke execute on function public.lease_freigeben(uuid, text) from public, anon;
revoke execute on function public.lease_holen(uuid, text, text, boolean, integer) from public, anon;
revoke execute on function public.set_team_member_role(uuid, text) from public, anon;
grant execute on function public.ablage_schreiben(uuid, text, text, text, text) to authenticated;
grant execute on function public.create_game_bridge(uuid, text) to authenticated;
grant execute on function public.einladung_einloesen(text, boolean) to authenticated;
grant execute on function public.einladung_erstellen(text, integer) to authenticated;
grant execute on function public.einladung_zurueckziehen(uuid) to authenticated;
grant execute on function public.get_team_members(uuid) to authenticated;
grant execute on function public.lease_freigeben(uuid, text) to authenticated;
grant execute on function public.lease_holen(uuid, text, text, boolean, integer) to authenticated;
grant execute on function public.set_team_member_role(uuid, text) to authenticated;
revoke execute on function public.prune_app_events() from public, anon, authenticated;
revoke execute on function public.prune_notifications() from public, anon, authenticated;
revoke execute on function public.bootstrap_first_team_owner() from public, anon, authenticated;
