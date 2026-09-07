-- Odin: personal settings and notification preferences.
-- One row per authenticated user; no game credentials are stored here.
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  selected_game_account_id uuid references public.game_accounts(id) on delete set null,
  attack_notifications boolean not null default true,
  bot_protection_notifications boolean not null default true,
  desktop_push boolean not null default false,
  sound_notifications boolean not null default true,
  compact_game_ui boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.user_preferences enable row level security;

create policy "users can read own preferences" on public.user_preferences
for select using (user_id = auth.uid());
create policy "users can insert own preferences" on public.user_preferences
for insert with check (user_id = auth.uid());
create policy "users can update own preferences" on public.user_preferences
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

after_user_preferences_updated;
