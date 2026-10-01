-- 024 (02.10.2026): oeffentliche IP je Geraet an der Geraete-Sperre.
alter table public.account_leases add column if not exists ip text, add column if not exists ip_at timestamptz;
create or replace function public.lease_ip_melden(p_geraet text, p_ip text)
returns integer
language plpgsql security definer set search_path = public
as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Nicht angemeldet'; end if;
  if p_ip is null or p_ip !~ '^[0-9a-fA-F:.]{3,45}$' then raise exception 'Ungültige IP'; end if;
  update public.account_leases l set ip = p_ip, ip_at = now()
   where l.geraet_id = p_geraet and public.is_team_member(l.team_id);
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke execute on function public.lease_ip_melden(text, text) from public, anon;
grant execute on function public.lease_ip_melden(text, text) to authenticated;
