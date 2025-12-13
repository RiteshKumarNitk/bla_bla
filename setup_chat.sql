-- Create Messages table for Ride Chat
create table messages (
  id uuid default uuid_generate_v4() primary key,
  ride_id uuid references rides(id) not null,
  sender_id uuid references profiles(id) not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table messages enable row level security;

-- Policies
create policy "Users can view messages for rides they are part of." on messages
  for select using (
    exists (
      select 1 from bookings
      where bookings.ride_id = messages.ride_id
      and bookings.passenger_id = auth.uid()
    )
    or
    exists (
      select 1 from rides
      where rides.id = messages.ride_id
      and rides.driver_id = auth.uid()
    )
  );

create policy "Users can insert messages for rides they are part of." on messages
  for insert with check (
    exists (
      select 1 from bookings
      where bookings.ride_id = messages.ride_id
      and bookings.passenger_id = auth.uid()
    )
    or
    exists (
      select 1 from rides
      where rides.id = messages.ride_id
      and rides.driver_id = auth.uid()
    )
  );
