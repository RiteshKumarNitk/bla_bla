-- Add current location columns to RIDES table for live tracking
alter table rides add column if not exists current_lat double precision;
alter table rides add column if not exists current_lng double precision;

-- Index for faster queries (optional but good)
create index if not exists rides_current_loc_idx on rides (current_lat, current_lng);

-- Function to update ride location (Driver only)
create or replace function update_ride_location(ride_id_input uuid, lat double precision, lng double precision)
returns void
language plpgsql
security definer
as $$
begin
  update rides 
  set current_lat = lat, current_lng = lng
  where id = ride_id_input
  and driver_id = auth.uid(); -- Ensure only the driver can update
end;
$$;
