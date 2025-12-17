-- 1. Enable RLS on all tables
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 2. Rides Policies
-- Allow anyone to view rides (for search)
DROP POLICY IF EXISTS "Public rides access" ON rides;
CREATE POLICY "Public rides access" ON rides FOR SELECT USING (true);

-- Allow drivers to update their own rides (e.g. seats, location)
DROP POLICY IF EXISTS "Drivers update own rides" ON rides;
CREATE POLICY "Drivers update own rides" ON rides FOR UPDATE USING (auth.uid() = driver_id);

-- Allow authenticated users to insert rides
DROP POLICY IF EXISTS "Auth users create rides" ON rides;
CREATE POLICY "Auth users create rides" ON rides FOR INSERT WITH CHECK (auth.uid() = driver_id);


-- 3. Bookings Policies
-- Users can view their own bookings
DROP POLICY IF EXISTS "View own bookings" ON bookings;
CREATE POLICY "View own bookings" ON bookings FOR SELECT USING (auth.uid() = passenger_id);

-- Drivers can view bookings for their rides
DROP POLICY IF EXISTS "Drivers view ride bookings" ON bookings;
CREATE POLICY "Drivers view ride bookings" ON bookings FOR SELECT USING (
  EXISTS (SELECT 1 FROM rides WHERE id = bookings.ride_id AND driver_id = auth.uid())
);

-- Users can create bookings
DROP POLICY IF EXISTS "Create booking" ON bookings;
CREATE POLICY "Create booking" ON bookings FOR INSERT WITH CHECK (auth.uid() = passenger_id);

-- Drivers/Passengers can update payment status (simplification)
DROP POLICY IF EXISTS "Update booking" ON bookings;
CREATE POLICY "Update booking" ON bookings FOR UPDATE USING (
  auth.uid() = passenger_id OR 
  EXISTS (SELECT 1 FROM rides WHERE id = bookings.ride_id AND driver_id = auth.uid())
);


-- 4. Messages Policies (Fixed for Realtime)
-- Allow participants to view messages. 
-- Note: We rely on the fact that we can now query 'rides' and 'bookings' because of above policies.
DROP POLICY IF EXISTS "View messages" ON messages;
CREATE POLICY "View messages" ON messages FOR SELECT USING (
    -- User is the driver
    (SELECT driver_id FROM rides WHERE id = messages.ride_id) = auth.uid()
    OR
    -- User is a passenger
    EXISTS (
        SELECT 1 FROM bookings 
        WHERE bookings.ride_id = messages.ride_id 
        AND bookings.passenger_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Insert messages" ON messages;
CREATE POLICY "Insert messages" ON messages FOR INSERT WITH CHECK (
    -- User is the driver
    (SELECT driver_id FROM rides WHERE id = messages.ride_id) = auth.uid()
    OR
    -- User is a passenger
    EXISTS (
        SELECT 1 FROM bookings 
        WHERE bookings.ride_id = messages.ride_id 
        AND bookings.passenger_id = auth.uid()
    )
);

-- 5. Enable Realtime Replication
-- Ensure tables are in the publication
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE rides;
-- bookings usually don't need realtime unless we track status live, but safer to add
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
