-- PulseQR Profiles Table Migration
-- Creates the profiles table needed for user authentication

-- Create user_role enum if it doesn't exist
do $$ begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('student','lecturer','admin');
  end if;
end $$;

-- Create profiles table
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users on delete set null,
  school_id text unique not null,
  school_email text unique not null,
  full_name text not null,
  role public.user_role not null,
  active boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS on profiles table
alter table public.profiles enable row level security;

-- Create policies for profiles table
create policy "authenticated_users_can_select_own_profile" on public.profiles
  for select using (auth.uid() = auth_user_id);

create policy "authenticated_users_can_update_own_profile" on public.profiles
  for update using (auth.uid() = auth_user_id);

create policy "admin_can_select_all_profiles" on public.profiles
  for select using (exists (
    select 1 from public.profiles p
    where p.auth_user_id = auth.uid()
    and p.role = 'admin'
  ));

-- Create indexes for faster queries
create unique index if not exists profiles_school_email on public.profiles (lower(school_email));
create index if not exists profiles_role on public.profiles (role);
create index if not exists profiles_active on public.profiles (active);
create index if not exists profiles_auth_user_id on public.profiles (auth_user_id);

-- Add auto-update timestamp trigger
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$ language plpgsql;

create trigger if not exists update_profiles_updated_at before update on profiles
  for each row execute function public.update_updated_at_column();

-- Grant access to authenticated users
grant select, update on public.profiles to authenticated;