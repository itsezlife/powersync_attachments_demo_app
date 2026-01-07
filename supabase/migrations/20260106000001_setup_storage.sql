-- -----------------------------------------------------
-- Supabase Storage Setup
-- Creates storage buckets and RLS policies for file uploads
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Storage Buckets
-- -----------------------------------------------------

-- Create post_attachments bucket for storing post attachments (images, files, etc.)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'post_attachments'
    ) THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'post_attachments',
            'post_attachments',
            true, -- Public bucket, files can be accessed without auth
            52428800, -- 50MB file size limit
            ARRAY[
                'image/jpeg',
                'image/png',
                'image/gif',
                'image/jpg',
                'image/webp',
                'image/heic',
                'image/heif',
                'video/mp4',
                'video/quicktime',
                'video/webm',
                'application/pdf',
                'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            ]
        );
    END IF;
END
$$;

-- Create avatars bucket for storing user avatar images
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM storage.buckets WHERE id = 'avatars'
    ) THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'avatars',
            'avatars',
            true, -- Public bucket, avatars can be accessed without auth
            5242880, -- 5MB file size limit
            ARRAY[
                'image/jpeg',
                'image/png',
                'image/gif',
                'image/webp',
                'image/heic',
                'image/heif'
            ]
        );
    END IF;
END
$$;

-- -----------------------------------------------------
-- Storage Helper Functions
-- -----------------------------------------------------

-- Function to check if the current user owns a post
CREATE OR REPLACE FUNCTION is_post_owner(post_id uuid)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM posts
        WHERE id = post_id
        AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION is_post_owner(uuid) IS 
'Checks if the authenticated user is the owner of the specified post';

-- -----------------------------------------------------
-- Storage RLS Policies
-- Note: RLS is already enabled on storage.objects by Supabase
-- -----------------------------------------------------

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can view post attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload post attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Users can update their own post attachments" ON storage.objects;
    DROP POLICY IF EXISTS "Users can delete their own post attachments" ON storage.objects;
    
    DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload their own avatar" ON storage.objects;
    DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
    DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
EXCEPTION
    WHEN undefined_object THEN NULL;
END
$$;

-- -----------------------------------------------------
-- Post Attachments Bucket Policies
-- -----------------------------------------------------

-- Anyone can view post attachments (public bucket)
CREATE POLICY "Anyone can view post attachments"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'post_attachments');

-- Authenticated users can upload post attachments
CREATE POLICY "Authenticated users can upload post attachments"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'post_attachments'
        AND auth.role() = 'authenticated'
    );

-- Users can update their own post attachments
-- File path format: {post_id}/{filename}
CREATE POLICY "Users can update their own post attachments"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'post_attachments'
        AND auth.role() = 'authenticated'
        AND is_post_owner((string_to_array(name, '/'))[1]::uuid)
    );

-- Users can delete their own post attachments
CREATE POLICY "Users can delete their own post attachments"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'post_attachments'
        AND auth.role() = 'authenticated'
        AND is_post_owner((string_to_array(name, '/'))[1]::uuid)
    );

-- -----------------------------------------------------
-- Avatars Bucket Policies
-- -----------------------------------------------------

-- Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- Users can upload their own avatar
-- File path format: {user_id}/{filename}
CREATE POLICY "Authenticated users can upload their own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (string_to_array(name, '/'))[1]::uuid = auth.uid()
    );

-- Users can update their own avatar
CREATE POLICY "Users can update their own avatar"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (string_to_array(name, '/'))[1]::uuid = auth.uid()
    );

-- Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (string_to_array(name, '/'))[1]::uuid = auth.uid()
    );

