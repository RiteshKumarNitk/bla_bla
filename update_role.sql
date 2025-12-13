-- Add role column to profiles if it doesn't exist
-- Note: SQLite syntax (local) might differ from Postgres.
-- This script is for Supabase Postgres.

alter table profiles 
add column if not exists role text default 'customer' check (role in ('customer', 'driver', 'admin'));

-- Policy updates might be needed based on role, but for now basic auth checks suffice.
