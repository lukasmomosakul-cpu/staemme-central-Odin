-- Teamzentrale Odin: network profile management.
-- Run once in the Supabase SQL Editor.

create policy "managers can insert network profiles" on public.network_profiles
for insert with check (
  exists (select 1 from public.team_members m where m.team_id = network_profiles.team_id and m.user_id = auth.uid() and m.role in ('Owner','Admin'))
);

create policy "managers can update network profiles" on public.network_profiles
for update using (
  exists (select 1 from public.team_members m where m.team_id = network_profiles.team_id and m.user_id = auth.uid() and m.role in ('Owner','Admin'))
) with check (
  exists (select 1 from public.team_members m where m.team_id = network_profiles.team_id and m.user_id = auth.uid() and m.role in ('Owner','Admin'))
);

create policy "managers can delete network profiles" on public.network_profiles
for delete using (
  exists (select 1 from public.team_members m where m.team_id = network_profiles.team_id and m.user_id = auth.uid() and m.role in ('Owner','Admin'))
);
