create table if not exists public.game_account_credentials (
  id uuid primary key default gen_random_uuid(),
  game_account_id uuid not null references public.game_accounts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  username text not null default '',
  password_encrypted text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (game_account_id, user_id)
);

alter table public.game_account_credentials enable row level security;

create policy "users manage own game credentials"
on public.game_account_credentials
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
