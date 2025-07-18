-- Supabase数据库行级安全策略 (RLS)
-- 确保用户只能访问和修改自己的数据

-- 启用RLS
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- 文章表RLS策略
-- 1. 所有人都可以查看已发布的文章
CREATE POLICY "Anyone can view published articles" ON articles
    FOR SELECT USING (true);

-- 2. 只有认证用户可以创建文章
CREATE POLICY "Authenticated users can create articles" ON articles
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 3. 用户只能更新自己的文章
CREATE POLICY "Users can update own articles" ON articles
    FOR UPDATE USING (auth.uid()::text = user_id);

-- 4. 用户只能删除自己的文章
CREATE POLICY "Users can delete own articles" ON articles
    FOR DELETE USING (auth.uid()::text = user_id);

-- 评论表RLS策略
-- 1. 所有人都可以查看评论
CREATE POLICY "Anyone can view comments" ON comments
    FOR SELECT USING (true);

-- 2. 只有认证用户可以创建评论
CREATE POLICY "Authenticated users can create comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 3. 用户只能更新自己的评论
CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid()::text = user_id);

-- 4. 用户只能删除自己的评论
CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid()::text = user_id);

-- 用户资料表（如果需要额外的用户信息）
-- 创建用户资料表
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    username TEXT UNIQUE,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 启用用户资料表RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 用户资料表RLS策略
-- 1. 所有人都可以查看用户资料
CREATE POLICY "Anyone can view user profiles" ON user_profiles
    FOR SELECT USING (true);

-- 2. 用户只能创建自己的资料
CREATE POLICY "Users can create own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. 用户只能更新自己的资料
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 创建触发器自动创建用户资料
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 更新文章表结构以使用auth.users的ID
-- 如果需要迁移现有数据，请谨慎执行
-- ALTER TABLE articles ALTER COLUMN user_id TYPE UUID USING user_id::UUID;
-- ALTER TABLE comments ALTER COLUMN user_id TYPE UUID USING user_id::UUID;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_articles_user_id ON articles(user_id);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_article_id ON comments(article_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON user_profiles(username);