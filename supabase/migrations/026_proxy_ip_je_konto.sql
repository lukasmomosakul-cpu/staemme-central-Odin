-- 026 (03.10.2026): IP je Konto bei Proxy-Konten.
-- lease_ip_melden (024) schreibt die Geraete-IP an ALLE Sperren des Geraets.
-- Konten mit Proxy (game_accounts.proxy) laufen aber ueber eine andere IP -
-- die meldet die App ueber lease_ip_melden_konto. Damit sich beide nicht
-- abwechselnd ueberschreiben, laesst die Geraete-Meldung Proxy-Konten aus.
create or replace function public.lease_ip_melden(p_geraet text, p_ip text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;
  update public.account_leases l set ip = p_ip, ip_at = now()
   where l.geraet_id = p_geraet and public.is_team_member(l.team_id)
     and not exists (select 1 from public.game_accounts g
                      where g.id::text = l.account_id::text and coalesce(trim(g.proxy),'') <> '');
  get diagnostics n = row_count;
  return n;
end;
$$;
create or replace function public.lease_ip_melden_konto(p_geraet text, p_konto text, p_ip text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;
  update public.account_leases l set ip = p_ip, ip_at = now()
   where l.geraet_id = p_geraet and l.account_id::text = p_konto and public.is_team_member(l.team_id);
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke all on function public.lease_ip_melden_konto(text,text,text) from public, anon;
grant execute on function public.lease_ip_melden_konto(text,text,text) to authenticated;
