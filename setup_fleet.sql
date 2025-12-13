-- Add Fleet Management fields to Profiles
alter table profiles 
add column if not exists dl_number text,
add column if not exists aadhar_number text,
add column if not exists vehicle_details jsonb default '{}'::jsonb, -- { "model": "Toyota Etios", "plate": "DL-01-...", "owner": "self" }
add column if not exists is_verified boolean default false;

-- Create Shift Logs table
create table shift_logs (
  id uuid default uuid_generate_v4() primary key,
  driver_id uuid references profiles(id) not null,
  check_in_time timestamp with time zone default timezone('utc'::text, now()) not null,
  check_out_time timestamp with time zone,
  
  -- Prevent overlapping shifts for same driver (optional constraint)
  -- For MVP, simple logging is enough
  constraint shift_logs_check_out_after_check_in check (check_out_time > check_in_time)
);

-- Enable RLS
alter table shift_logs enable row level security;

-- Policies for Shift Logs
create policy "Drivers can view their own shifts." on shift_logs
  for select using (auth.uid() = driver_id);
  
create policy "Admins can view all shifts." on shift_logs
  for select using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
      and profiles.role = 'admin'
    )
  );

create policy "Drivers can insert check-in." on shift_logs
  for insert with check (auth.uid() = driver_id);

create policy "Drivers can update check-out." on shift_logs
  for update using (auth.uid() = driver_id);
