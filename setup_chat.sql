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

-- Allow any authenticated user to view messages if they are part of the ride
-- Either they are the driver of the ride OR they have a booking for the ride
create policy "Users can view messages" on messages
  for select using (
    auth.uid() = (select driver_id from rides where id = messages.ride_id)
    or
    exists (
      select 1 from bookings
      where bookings.ride_id = messages.ride_id
      and bookings.passenger_id = auth.uid()
    )
  );

-- Allow any authenticated user to insert messages if they are part of the ride
create policy "Users can insert messages" on messages
  for insert with check (
    auth.uid() = (select driver_id from rides where id = messages.ride_id)
    or
    exists (
      select 1 from bookings
      where bookings.ride_id = messages.ride_id
      and bookings.passenger_id = auth.uid()
    )
  );
