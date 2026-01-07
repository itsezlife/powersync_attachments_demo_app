-- -----------------------------------------------------
-- Auto-delete Storage Files on Post Attachments Delete
-- Automatically removes storage files when post_attachments records are deleted
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Helper Function: Delete Storage Object
-- -----------------------------------------------------

-- Drop existing trigger first if it exists
DROP TRIGGER IF EXISTS trigger_delete_post_attachment_storage ON post_attachments;

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS delete_post_attachment_storage();
DROP FUNCTION IF EXISTS delete_storage_object(text, text);

-- Function to delete a storage object
CREATE OR REPLACE FUNCTION delete_storage_object(bucket_name text, object_path text)
RETURNS void AS $$
BEGIN
    DELETE FROM storage.objects
    WHERE bucket_id = bucket_name
    AND name = object_path;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION delete_storage_object(text, text) IS 
'Deletes a storage object from the specified bucket and path';

-- -----------------------------------------------------
-- Trigger Function: Delete Storage Files on Post Attachment Delete
-- -----------------------------------------------------

-- Function to delete storage files when post_attachment is deleted
CREATE OR REPLACE FUNCTION delete_post_attachment_storage()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete the specific attachment file if asset_url exists
    IF OLD.asset_url IS NOT NULL AND OLD.asset_url != '' THEN
        -- Extract the file path from the asset_url
        -- Expected format: https://...storage.../post_attachments/{post_id}/{filename}
        -- We want to extract: {post_id}/{filename}
        DECLARE
            file_path text;
        BEGIN
            -- Extract path after 'post_attachments/'
            file_path := substring(OLD.asset_url from 'post_attachments/(.*)');
            
            IF file_path IS NOT NULL AND file_path != '' THEN
                PERFORM delete_storage_object('post_attachments', file_path);
            END IF;
        END;
    END IF;
    
    -- Delete thumbnail if thumb_url exists
    IF OLD.thumb_url IS NOT NULL AND OLD.thumb_url != '' THEN
        DECLARE
            thumb_path text;
        BEGIN
            thumb_path := substring(OLD.thumb_url from 'post_attachments/(.*)');
            
            IF thumb_path IS NOT NULL AND thumb_path != '' THEN
                PERFORM delete_storage_object('post_attachments', thumb_path);
            END IF;
        END;
    END IF;
    
    -- Delete image if image_url exists
    IF OLD.image_url IS NOT NULL AND OLD.image_url != '' THEN
        DECLARE
            image_path text;
        BEGIN
            image_path := substring(OLD.image_url from 'post_attachments/(.*)');
            
            IF image_path IS NOT NULL AND image_path != '' THEN
                PERFORM delete_storage_object('post_attachments', image_path);
            END IF;
        END;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION delete_post_attachment_storage() IS 
'Automatically deletes storage files (asset, thumbnail, image) when a post_attachment record is deleted';

-- Create trigger
CREATE TRIGGER trigger_delete_post_attachment_storage
    BEFORE DELETE ON post_attachments
    FOR EACH ROW
    EXECUTE FUNCTION delete_post_attachment_storage();

-- -----------------------------------------------------
-- Trigger Function: Delete All Post Storage Files on Post Delete
-- Deletes all files in the post's folder when the post is deleted
-- -----------------------------------------------------

-- Drop existing trigger first if it exists
DROP TRIGGER IF EXISTS trigger_delete_post_storage ON posts;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS delete_post_storage_folder();

-- Function to delete all storage files for a post
CREATE OR REPLACE FUNCTION delete_post_storage_folder()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete all storage objects in the post's folder
    -- Files are stored as: {post_id}/{filename}
    DELETE FROM storage.objects
    WHERE bucket_id = 'post_attachments'
    AND name LIKE OLD.id::text || '/%';
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION delete_post_storage_folder() IS 
'Automatically deletes all storage files in a post folder when the post is deleted';

-- Create trigger
CREATE TRIGGER trigger_delete_post_storage
    BEFORE DELETE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION delete_post_storage_folder();

-- -----------------------------------------------------
-- Cleanup Function: Delete Orphaned Storage Files
-- Deletes all storage files that don't have corresponding post_attachments records
-- -----------------------------------------------------

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS cleanup_orphaned_storage_files();

-- Function to cleanup orphaned storage files
CREATE OR REPLACE FUNCTION cleanup_orphaned_storage_files()
RETURNS TABLE(deleted_count integer, deleted_files text[]) AS $$
DECLARE
    deleted_file text;
    deleted_files_array text[] := '{}';
    total_deleted integer := 0;
BEGIN
    -- Delete storage objects that don't match any post_attachments records
    FOR deleted_file IN
        SELECT o.name
        FROM storage.objects o
        WHERE o.bucket_id = 'post_attachments'
        AND NOT EXISTS (
            -- Check if file path matches any asset_url
            SELECT 1 FROM post_attachments pa
            WHERE pa.asset_url LIKE '%' || o.name
            OR pa.thumb_url LIKE '%' || o.name
            OR pa.image_url LIKE '%' || o.name
        )
    LOOP
        -- Delete the orphaned file
        DELETE FROM storage.objects
        WHERE bucket_id = 'post_attachments'
        AND name = deleted_file;
        
        -- Add to results
        deleted_files_array := array_append(deleted_files_array, deleted_file);
        total_deleted := total_deleted + 1;
    END LOOP;
    
    RETURN QUERY SELECT total_deleted, deleted_files_array;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION cleanup_orphaned_storage_files() IS 
'Removes all storage files in post_attachments bucket that do not have corresponding records in post_attachments table. Returns count and list of deleted files.';

-- -----------------------------------------------------
-- Run Initial Cleanup
-- Delete all orphaned files that currently exist
-- -----------------------------------------------------

DO $$
DECLARE
    cleanup_result record;
BEGIN
    -- Run the cleanup function
    SELECT * INTO cleanup_result FROM cleanup_orphaned_storage_files();
    
    -- Log the results
    RAISE NOTICE 'Cleanup completed: % orphaned files deleted', cleanup_result.deleted_count;
    
    IF cleanup_result.deleted_count > 0 THEN
        RAISE NOTICE 'Deleted files: %', cleanup_result.deleted_files;
    END IF;
END
$$;

