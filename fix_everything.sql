-- 1. Ensure Profiles table has necessary columns
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS role text default 'customer',
ADD COLUMN IF NOT EXISTS email text;

-- 2. Create the Trigger Function to handle new user signups automatically
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role, email)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    COALESCE(new.raw_user_meta_data->>'role', 'customer'),
    new.email
  );
  RETURN new;
END;
$$;

-- 3. Bind the Trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. Backfill missing profiles for existing users (Fix for "No Usage Found")
INSERT INTO public.profiles (id, full_name, role, email)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'full_name', 'Unknown User'),
    COALESCE(raw_user_meta_data->>'role', 'customer'),
    email
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);

-- 5. Seed Admin and Fleet Data (The Main Fix)
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get the first user (now guaranteed to exist if you signed up)
  SELECT id INTO v_user_id FROM profiles LIMIT 1;
  
  IF v_user_id IS NOT NULL THEN
      RAISE NOTICE 'Seeding data for User ID: %', v_user_id;

      -- Make Admin
      UPDATE profiles 
      SET role = 'admin'
      WHERE id = v_user_id;

      -- Update others to be drivers
      UPDATE profiles
      SET role = 'driver', is_verified = true
      WHERE id != v_user_id;

      -- Seed Shift Logs (if missing)
      IF NOT EXISTS (SELECT 1 FROM shift_logs WHERE driver_id = v_user_id) THEN
        INSERT INTO shift_logs (driver_id, check_in_time)
        VALUES (v_user_id, now() - interval '4 hours');
      END IF;

      -- Seed Rides
      IF NOT EXISTS (SELECT 1 FROM rides WHERE driver_id = v_user_id) THEN
        INSERT INTO rides (driver_id, origin, destination, departure_time, price, total_seats, available_seats, car_model)
        VALUES 
          (v_user_id, 'Connaught Place', 'Gurgaon Cyber Hub', now() + interval '2 hours', 350, 4, 3, 'Toyota Glanza'),
          (v_user_id, 'Noida Sec 18', 'Delhi Airport T3', now() + interval '5 hours', 500, 4, 4, 'Maruti Dzire');
      END IF;
  ELSE
      RAISE NOTICE 'Still no users found. Please sign up in the app first.';
  END IF;
END $$;
