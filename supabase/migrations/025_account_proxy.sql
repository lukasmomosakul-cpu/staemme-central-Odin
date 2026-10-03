-- 025 (03.10.2026): Pro-Konto-Proxy (Mobilproxy je Spielkonto).
-- Format host:port:user:pass; nullable = kein Proxy. Schutz ueber die
-- bestehende RLS von game_accounts (nur Team-Mitglieder). Proxy-Passwort
-- liegt damit in der DB (Team-sichtbar), anders als das geraetelokale
-- Spielpasswort - Proxy-Zugaenge sind rotierbar.
alter table public.game_accounts add column if not exists proxy text;
