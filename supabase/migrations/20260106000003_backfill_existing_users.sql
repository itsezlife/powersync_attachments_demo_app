-- -----------------------------------------------------
-- Backfill existing authenticated users into public.users table
-- This migration ensures any users who signed up before the trigger
-- was created are now present in the public.users table
-- -----------------------------------------------------

-- Insert any existing auth.users that are missing from public.users
INSERT INTO public.users (id, name, email, avatar_url, created_at, updated_at)
SELECT 
    au.id,
    COALESCE(au.raw_user_meta_data->>'name', au.email, 'Unknown User') as name,
    COALESCE(au.email, '') as email,
    au.raw_user_meta_data->>'avatar_url' as avatar_url,
    COALESCE(au.created_at, NOW()) as created_at,
    NOW() as updated_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
)
ON CONFLICT (id) DO NOTHING;


