-- Create Reviews table
create table reviews (
  id uuid default uuid_generate_v4() primary key,
  ride_id uuid references rides(id) not null,
  reviewer_id uuid references profiles(id) not null,
  reviewee_id uuid references profiles(id) not null,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Ensure one review per ride per pair
  unique(ride_id, reviewer_id, reviewee_id)
);

-- Enable RLS
alter table reviews enable row level security;

-- Policies
create policy "Reviews are viewable by everyone." on reviews
  for select using (true);

create policy "Users can insert their own reviews." on reviews
  for insert with check (auth.uid() = reviewer_id);

-- Add rating_average to profiles if not exists (or we can calculate dynamic)
alter table profiles add column if not exists rating_average numeric default 5.0;
alter table profiles add column if not exists rating_count integer default 0;
