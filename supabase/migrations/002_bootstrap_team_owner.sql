-- Teamzentrale Odin: bootstrap the first registered user as team owner.
-- Run this once in Supabase SQL Editor after schema.sql.

create or replace function public.bootstrap_first_team_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_team uuid;
begin
  select id into existing_team from public.teams order by created_at asc limit 1;

  if existing_team is null then
    insert into public.teams (name) values ('Teamzentrale Odin') returning id into existing_team;
    insert into public.team_members (team_id, user_id, role)
      values (existing_team, new.id, 'Owner')
      on conflict (team_id, user_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_bootstrap on auth.users;
create trigger on_auth_user_created_bootstrap
after insert on auth.users
for each row execute function public.bootstrap_first_team_owner();

-- Bootstrap an already-created first account (if the project was registered before this migration).
do $$
declare
  first_user uuid;
  first_team uuid;
begin
  select id into first_user from auth.users order by created_at asc limit 1;
  if first_user is not null then
    select id into first_team from public.teams order by created_at asc limit 1;
    if first_team is null then
      insert into public.teams (name) values ('Teamzentrale Odin') returning id into first_team;
    end if;
    insert into public.team_members (team_id, user_id, role)
      values (first_team, first_user, 'Owner')
      on conflict (team_id, user_id) do update set role = 'Owner';
  end if;
end $$;
