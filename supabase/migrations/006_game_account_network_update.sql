-- Allow team managers to change the network profile of a game account.
create policy "Managers can update game accounts"
on public.game_accounts for update
to authenticated
using (public.is_team_manager(team_id))
with check (public.is_team_manager(team_id));
