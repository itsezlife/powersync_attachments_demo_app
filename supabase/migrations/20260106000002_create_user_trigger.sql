-- -----------------------------------------------------
-- Auto-create user in public.users table when they sign up
-- This ensures the foreign key constraint in posts table is satisfied
-- -----------------------------------------------------

-- Grant necessary permissions to create trigger on auth.users
-- Note: This requires superuser/admin privileges
DO $$
BEGIN
    -- Grant usage on auth schema if not already granted
    GRANT USAGE ON SCHEMA auth TO postgres, authenticated, service_role;
    
    -- Grant select on auth.users to the postgres role
    GRANT SELECT ON auth.users TO postgres, authenticated, service_role;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Insufficient privileges to grant permissions. Skipping...';
END $$;

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Function to handle new user creation
-- Automatically creates a record in public.users when a user signs up
-- SECURITY DEFINER ensures this runs with the privileges of the function creator
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
    user_name TEXT;
    user_avatar TEXT;
BEGIN
    -- Extract user metadata (name and avatar_url from raw_user_meta_data)
    user_name := COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, 'Unknown User');
    user_avatar := NEW.raw_user_meta_data->>'avatar_url';

    -- Insert the user into public.users table
    INSERT INTO public.users (id, name, email, avatar_url, created_at, updated_at)
    VALUES (
        NEW.id,
        user_name,
        COALESCE(NEW.email, ''),
        user_avatar,
        COALESCE(NEW.created_at, NOW()),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET
        name = COALESCE(EXCLUDED.name, public.users.name),
        email = COALESCE(EXCLUDED.email, public.users.email),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
        updated_at = NOW();

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the auth operation
        RAISE WARNING 'Failed to create user in public.users: %', SQLERRM;
        RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 
'Automatically creates or updates a user record in public.users when they sign up via Supabase Auth';

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, authenticated, service_role;

-- Create trigger on auth.users table
-- This requires elevated privileges
DO $$
BEGIN
    CREATE TRIGGER on_auth_user_created
        AFTER INSERT OR UPDATE ON auth.users
        FOR EACH ROW
        EXECUTE FUNCTION public.handle_new_user();
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE EXCEPTION 'Insufficient privileges to create trigger on auth.users. Please run this migration with superuser privileges or use Supabase Dashboard to apply it.';
    WHEN duplicate_object THEN
        RAISE NOTICE 'Trigger already exists. Skipping...';
END $$;


