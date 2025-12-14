-- Secure Function to Delete Users
-- This function allows an Admin to delete a user from auth.users
-- It uses SECURITY DEFINER to run with privileges of the creator (postgres/superuser)
-- BUT we must manually enforce that only app admins can call it.

CREATE OR REPLACE FUNCTION delete_user_by_admin(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Security Check: Ensure the caller is an Admin
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only Admins can delete users.';
  END IF;

  -- 2. Delete from auth.users
  -- This will cascade to profiles, rides, etc. if foreign keys are set to cascade
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;
