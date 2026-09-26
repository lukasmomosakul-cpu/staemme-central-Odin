-- 020 (27.09.2026): Einladungscodes ohne Ablauf. gueltig_stunden 0/NULL ->
-- gueltig_bis NULL (einmalig bleibt der Code trotzdem). Funktionen
-- einladung_erstellen und einladung_einloesen entsprechend ersetzt
-- (vollstaendiger Text wie in Supabase eingespielt, siehe 019 + diese Aenderungen).
alter table public.team_einladungen alter column gueltig_bis drop not null;
