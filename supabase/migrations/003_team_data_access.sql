-- Teamzentrale Odin: allow authenticated team members to manage their own team accounts.

create policy "members can insert accounts"
on public.game_accounts
for insert
with check (public.is_team_member(team_id));

create policy "members can update accounts"
on public.game_accounts
for update
using (public.is_team_member(team_id))
with check (public.is_team_member(team_id));

create policy "members can delete accounts"
on public.game_accounts
for delete
using (public.is_team_member(team_id));
