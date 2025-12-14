-- Wrapped in a transaction block to use variables
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  -- 1. Get a valid User ID
  -- Try auth.uid() first, fallback to the first user in the profiles table
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM profiles LIMIT 1;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No usage found! Please sign up a user in the app first.';
  END IF;

  RAISE NOTICE 'Using User ID: %', v_user_id;

  -- 2. Make this user Admin
  UPDATE profiles 
  SET role = 'admin'
  WHERE id = v_user_id;

  -- 3. Update any OTHER users to be 'driver' (so we have drivers to manage)
  UPDATE profiles
  SET role = 'driver', is_verified = true
  WHERE id != v_user_id;

  -- 4. Create Dummy Shift Log (if not exists recently)
  IF NOT EXISTS (SELECT 1 FROM shift_logs WHERE driver_id = v_user_id AND check_in_time > now() - interval '1 day') THEN
    INSERT INTO shift_logs (driver_id, check_in_time)
    VALUES (v_user_id, now() - interval '4 hours');
  END IF;

  -- 5. Create Dummy Rides
  INSERT INTO rides (driver_id, origin, destination, departure_time, price, total_seats, available_seats, car_model)
  VALUES 
    (v_user_id, 'Connaught Place', 'Gurgaon Cyber Hub', now() + interval '2 hours', 350, 4, 3, 'Toyota Glanza'),
    (v_user_id, 'Noida Sec 18', 'Delhi Airport T3', now() + interval '5 hours', 500, 4, 4, 'Maruti Dzire');

END $$;

-- 6. Fix Policies (Outside DO block)
-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all rides" ON rides;

-- Re-create Policies
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can view all rides" ON rides
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
