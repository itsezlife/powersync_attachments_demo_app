-- -----------------------------------------------------
-- Enable UUID extension
-- -----------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------
-- Users Table
-- Stores user information for the application
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comments on users table
COMMENT ON TABLE users IS 'User accounts and profile information';
COMMENT ON COLUMN users.id IS 'Unique identifier for the user';
COMMENT ON COLUMN users.name IS 'Display name of the user';
COMMENT ON COLUMN users.email IS 'Email address (unique) for the user';
COMMENT ON COLUMN users.avatar_url IS 'URL to user avatar image';
COMMENT ON COLUMN users.created_at IS 'Timestamp when user was created';
COMMENT ON COLUMN users.updated_at IS 'Timestamp when user was last updated';

-- Create indexes for users
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'users' AND indexname = 'idx_users_email') THEN
        CREATE INDEX idx_users_email ON users(email);
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'users' AND indexname = 'idx_users_created_at') THEN
        CREATE INDEX idx_users_created_at ON users(created_at);
    END IF;
END
$$;

-- -----------------------------------------------------
-- Posts Table
-- Stores posts/messages created by users
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comments on posts table
COMMENT ON TABLE posts IS 'Posts/messages created by users';
COMMENT ON COLUMN posts.id IS 'Unique identifier for the post';
COMMENT ON COLUMN posts.user_id IS 'ID of the user who created the post';
COMMENT ON COLUMN posts.content IS 'Text content of the post';
COMMENT ON COLUMN posts.created_at IS 'Timestamp when post was created';
COMMENT ON COLUMN posts.updated_at IS 'Timestamp when post was last updated';

-- Create indexes for posts
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'posts' AND indexname = 'idx_posts_user_id') THEN
        CREATE INDEX idx_posts_user_id ON posts(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'posts' AND indexname = 'idx_posts_created_at') THEN
        CREATE INDEX idx_posts_created_at ON posts(created_at);
    END IF;
END
$$;

-- -----------------------------------------------------
-- Post Attachments Table
-- Stores attachments associated with posts
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS post_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    type TEXT,
    title_link TEXT,
    title TEXT,
    thumb_url TEXT,
    text TEXT,
    pretext TEXT,
    og_scrape_url TEXT,
    image_url TEXT,
    footer_icon TEXT,
    footer TEXT,
    fields TEXT,
    fallback TEXT,
    color TEXT,
    author_name TEXT,
    author_link TEXT,
    author_icon TEXT,
    asset_url TEXT,
    actions TEXT,
    original_width INTEGER,
    original_height INTEGER,
    file_size INTEGER,
    mime_type TEXT,
    minithumbnail TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Comments on post_attachments table
COMMENT ON TABLE post_attachments IS 'Attachments (images, files, links, etc.) associated with posts';
COMMENT ON COLUMN post_attachments.id IS 'Unique identifier for the attachment';
COMMENT ON COLUMN post_attachments.post_id IS 'ID of the post this attachment belongs to';
COMMENT ON COLUMN post_attachments.type IS 'Type of attachment (image, file, link, etc.)';
COMMENT ON COLUMN post_attachments.title_link IS 'Link URL for the attachment title';
COMMENT ON COLUMN post_attachments.title IS 'Title of the attachment';
COMMENT ON COLUMN post_attachments.thumb_url IS 'URL to thumbnail image';
COMMENT ON COLUMN post_attachments.text IS 'Text content or description';
COMMENT ON COLUMN post_attachments.pretext IS 'Text displayed before the attachment';
COMMENT ON COLUMN post_attachments.og_scrape_url IS 'URL used for Open Graph scraping';
COMMENT ON COLUMN post_attachments.image_url IS 'URL to the main image';
COMMENT ON COLUMN post_attachments.footer_icon IS 'URL to footer icon';
COMMENT ON COLUMN post_attachments.footer IS 'Footer text';
COMMENT ON COLUMN post_attachments.fields IS 'JSON string of additional fields';
COMMENT ON COLUMN post_attachments.fallback IS 'Fallback text for unsupported clients';
COMMENT ON COLUMN post_attachments.color IS 'Color theme for the attachment';
COMMENT ON COLUMN post_attachments.author_name IS 'Name of the attachment author';
COMMENT ON COLUMN post_attachments.author_link IS 'Link to author profile';
COMMENT ON COLUMN post_attachments.author_icon IS 'URL to author icon';
COMMENT ON COLUMN post_attachments.asset_url IS 'URL to the actual asset/file';
COMMENT ON COLUMN post_attachments.actions IS 'JSON string of available actions';
COMMENT ON COLUMN post_attachments.original_width IS 'Original width of image/video';
COMMENT ON COLUMN post_attachments.original_height IS 'Original height of image/video';
COMMENT ON COLUMN post_attachments.file_size IS 'Size of the file in bytes';
COMMENT ON COLUMN post_attachments.mime_type IS 'MIME type of the attachment';
COMMENT ON COLUMN post_attachments.minithumbnail IS 'Base64 encoded mini thumbnail for quick preview';
COMMENT ON COLUMN post_attachments.created_at IS 'Timestamp when attachment was created';
COMMENT ON COLUMN post_attachments.updated_at IS 'Timestamp when attachment was last updated';

-- Create indexes for post_attachments
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'post_attachments' AND indexname = 'idx_post_attachments_post_id') THEN
        CREATE INDEX idx_post_attachments_post_id ON post_attachments(post_id);
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'post_attachments' AND indexname = 'idx_post_attachments_type') THEN
        CREATE INDEX idx_post_attachments_type ON post_attachments(type);
    END IF;
    
    IF NOT EXISTS (SELECT FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'post_attachments' AND indexname = 'idx_post_attachments_created_at') THEN
        CREATE INDEX idx_post_attachments_created_at ON post_attachments(created_at);
    END IF;
END
$$;

-- -----------------------------------------------------
-- Triggers for updated_at
-- -----------------------------------------------------

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
DROP TRIGGER IF EXISTS trigger_posts_updated_at ON posts;
DROP TRIGGER IF EXISTS trigger_post_attachments_updated_at ON post_attachments;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column() IS 
'Automatically updates the updated_at column to the current timestamp on row updates';

-- Create triggers for each table
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_post_attachments_updated_at
    BEFORE UPDATE ON post_attachments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------
-- Row Level Security (RLS) Policies
-- -----------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_attachments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view all users" ON users;
    DROP POLICY IF EXISTS "Users can update their own profile" ON users;
    DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
    
    DROP POLICY IF EXISTS "Users can view all posts" ON posts;
    DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
    DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
    DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
    
    DROP POLICY IF EXISTS "Users can view all post attachments" ON post_attachments;
    DROP POLICY IF EXISTS "Users can insert attachments to their own posts" ON post_attachments;
    DROP POLICY IF EXISTS "Users can update attachments on their own posts" ON post_attachments;
    DROP POLICY IF EXISTS "Users can delete attachments on their own posts" ON post_attachments;
EXCEPTION
    WHEN undefined_object THEN NULL;
END
$$;

-- Users policies
CREATE POLICY "Users can view all users"
    ON users FOR SELECT
    USING (true);

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Posts policies
CREATE POLICY "Users can view all posts"
    ON posts FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own posts"
    ON posts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts"
    ON posts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts"
    ON posts FOR DELETE
    USING (auth.uid() = user_id);

-- Post attachments policies
CREATE POLICY "Users can view all post attachments"
    ON post_attachments FOR SELECT
    USING (true);

CREATE POLICY "Users can insert attachments to their own posts"
    ON post_attachments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM posts
            WHERE posts.id = post_attachments.post_id
            AND posts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update attachments on their own posts"
    ON post_attachments FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM posts
            WHERE posts.id = post_attachments.post_id
            AND posts.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete attachments on their own posts"
    ON post_attachments FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM posts
            WHERE posts.id = post_attachments.post_id
            AND posts.user_id = auth.uid()
        )
    );

-- -----------------------------------------------------
-- PowerSync Publication
-- Enable logical replication for PowerSync
-- -----------------------------------------------------

-- Create publication for PowerSync with all tables
CREATE PUBLICATION powersync FOR TABLE users, posts, post_attachments;

COMMENT ON PUBLICATION powersync IS 
'Publication for PowerSync to enable real-time data synchronization via logical replication';

