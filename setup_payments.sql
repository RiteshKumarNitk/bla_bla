-- 1. Wallets Table
create table if not exists wallets (
  user_id uuid references profiles(id) primary key,
  balance numeric default 0.00 not null,
  currency text default 'INR',
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Transactions Table
create table if not exists transactions (
  id uuid default uuid_generate_v4() primary key,
  wallet_id uuid references wallets(user_id) not null,
  amount numeric not null, -- Positive for credit, negative for debit
  type text not null, -- 'earning', 'commission', 'withdrawal', 'refund'
  description text,
  reference_id uuid, -- Optional link to ride_id
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table wallets enable row level security;
alter table transactions enable row level security;

-- Policies
create policy "Users can view own wallet" on wallets
  for select using (auth.uid() = user_id);

create policy "Users can view own transactions" on transactions
  for select using (wallet_id = auth.uid());
  
-- Admin Policies
create policy "Admins can view all wallets" on wallets
  for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can view all transactions" on transactions
  for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- Function to ensure wallet exists
create or replace function public.create_wallet_if_missing(target_user_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.wallets (user_id) values (target_user_id)
  on conflict (user_id) do nothing;
end;
$$;
