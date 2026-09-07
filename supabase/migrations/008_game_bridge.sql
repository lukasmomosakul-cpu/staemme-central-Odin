-- Game bridge: read-only telemetry from a browser userscript.
-- No game credentials are stored here.
create extension if not exists pgcrypto;

create table if not exists public.game_account_bridges (
  id uuid primary key default gen_random_uuid(),
  game_account_id uuid not null references public.game_accounts(id) on delete cascade,
  ingest_token_hash text not null unique,
  last_seen_at timestamptz,
  last_payload jsonb,
  created_at timestamptz not null default now()
);

alter table public.game_account_bridges enable row level security;

create or replace function public.create_game_bridge(p_game_account_id uuid, p_ingest_token text)
returns public.game_account_bridges
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.game_account_bridges;
  uid uuid := auth.uid();
  team uuid;
begin
  select team_id into team from public.game_accounts where id = p_game_account_id;
  if team is null then raise exception 'game account not found'; end if;
  if not exists (select 1 from public.team_members where team_id=team and user_id=uid and role in ('Owner','Admin')) then
    raise exception 'not allowed';
  end if;
  insert into public.game_account_bridges(game_account_id, ingest_token_hash)
  values (p_game_account_id, encode(digest(p_ingest_token, 'sha256'),'hex'))
  returning * into result;
  return result;
end;
$$;

create or replace function public.ingest_game_telemetry(p_ingest_token text, p_payload jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.game_account_bridges
     set last_seen_at=now(), last_payload=p_payload
   where ingest_token_hash=encode(digest(p_ingest_token, 'sha256'),'hex');
  return found;
end;
$$;

grant execute on function public.create_game_bridge(uuid,text) to authenticated;
grant execute on function public.ingest_game_telemetry(text,jsonb) to anon, authenticated;

create policy "team can read own bridges"
on public.game_account_bridges for select
using (exists (
  select 1 from public.game_accounts ga
  join public.team_members tm on tm.team_id=ga.team_id
  where ga.id=game_account_bridges.game_account_id and tm.user_id=auth.uid()
));
