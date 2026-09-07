-- Allow team managers to change the network profile of a game account.
create policy "Managers can update game accounts"
on public.game_accounts for update
to authenticated
using (
  exists (
    select 1 from public.team_members actor
    where actor.team_id = game_accounts.team_id
      and actor.user_id = auth.uid()
      and actor.role in ('Owner','Admin')
  )
)
with check (
  exists (
    select 1 from public.team_members actor
    where actor.team_id = game_accounts.team_id
      and actor.user_id = auth.uid()
      and actor.role in ('Owner','Admin')
  )
);
