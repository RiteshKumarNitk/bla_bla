-- Add payment_status to bookings table
ALTER TABLE bookings 
ADD COLUMN payment_status text DEFAULT 'pending';
-- pending, paid

-- Add function to update payment status
CREATE OR REPLACE FUNCTION update_payment_status(booking_id_input uuid, status_input text)
RETURNS void AS $$
BEGIN
  UPDATE bookings
  SET payment_status = status_input
  WHERE id = booking_id_input;
END;
$$ LANGUAGE plpgsql;
