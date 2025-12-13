-- Create Profiles table (extends auth.users)
create table profiles (
  id uuid references auth.users not null primary key,
  full_name text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Create Rides table
create table rides (
  id uuid default uuid_generate_v4() primary key,
  driver_id uuid references profiles(id) not null,
  origin text not null,
  destination text not null,
  departure_time timestamp with time zone not null,
  price numeric not null,
  total_seats integer not null,
  available_seats integer not null,
  car_model text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table rides enable row level security;

create policy "Rides are viewable by everyone." on rides
  for select using (true);

create policy "Users can insert their own rides." on rides
  for insert with check (auth.uid() = driver_id);

create policy "Users can update their own rides." on rides
  for update using (auth.uid() = driver_id);

-- Create Bookings table
create table bookings (
  id uuid default uuid_generate_v4() primary key,
  ride_id uuid references rides(id) not null,
  passenger_id uuid references profiles(id) not null,
  seats_booked integer not null default 1,
  status text check (status in ('pending', 'confirmed', 'cancelled')) default 'confirmed',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table bookings enable row level security;

create policy "Users can view their own bookings." on bookings
  for select using (auth.uid() = passenger_id);

create policy "Drivers can view bookings for their rides." on bookings
  for select using (
    exists (
      select 1 from rides
      where rides.id = bookings.ride_id
      and rides.driver_id = auth.uid()
    )
  );

create policy "Users can insert their own bookings." on bookings
  for insert with check (auth.uid() = passenger_id);
