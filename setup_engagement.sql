-- 1. Promotions Table
create table promotions (
  id uuid default uuid_generate_v4() primary key,
  code text not null unique, -- e.g. "WELCOME200"
  description text not null, -- e.g. "Get ₹200 off your first ride"
  discount_amount numeric not null,
  valid_until timestamp with time zone,
  target_role text check (target_role in ('customer', 'driver', 'all')) default 'all',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for Promotions
alter table promotions enable row level security;

create policy "Everyone can view active promotions" on promotions
  for select using (true); -- Simplified for MVP, usually tailored to role

create policy "Admins can manage promotions" on promotions
  for all using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 2. Notifications Table
create table notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) not null, -- Specific user target
  title text not null,
  message text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for Notifications
alter table notifications enable row level security;

create policy "Users can view their own notifications" on notifications
  for select using (auth.uid() = user_id);

create policy "Admins can insert notifications" on notifications
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );
  
-- 3. Mock Data for Promotions
insert into promotions (code, description, discount_amount, target_role, valid_until)
values 
  ('WELCOME200', 'Get ₹200 off your first ride!', 200, 'customer', now() + interval '30 days'),
  ('DRIVER500', 'Complete 5 rides for ₹500 bonus!', 500, 'driver', now() + interval '7 days');
