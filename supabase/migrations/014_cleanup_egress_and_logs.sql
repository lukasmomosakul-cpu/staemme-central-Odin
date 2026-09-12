-- 014: Egress-Schicht entfernen, Protokollrauschen aus dem Abgleich werfen
--
-- network_profiles/network_profile_id dienten der Zuweisung fester
-- Ausgangs-IPs pro Spielaccount und wurden von keinem Codepfad mehr genutzt.
alter table public.game_accounts drop column if exists network_profile_id;
drop table if exists public.network_profiles cascade;

-- tw_console_log lag bei ~288 KB je Account und wurde bei jeder Aenderung
-- mitgeschickt, ohne dass es jemand liest.
delete from public.godbot_settings where skey in ('tw_console_log','tw_debug_log');
