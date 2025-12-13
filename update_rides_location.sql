-- Add coordinate columns to rides table
alter table rides 
add column if not exists origin_lat double precision,
add column if not exists origin_lng double precision,
add column if not exists dest_lat double precision,
add column if not exists dest_lng double precision;
