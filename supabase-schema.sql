-- ============================================================
-- 城建青协志愿者管理系统 - Supabase 完整建表脚本
-- 使用前请确认已在 Supabase Dashboard → Authentication 中开启 Email Auth
-- ============================================================

-- 1. 成员表（关联 auth.users）
CREATE TABLE IF NOT EXISTS members (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  gender VARCHAR(10),
  student_id VARCHAR(20),
  phone VARCHAR(20),
  department VARCHAR(50),
  role VARCHAR(50) DEFAULT '会员',
  position VARCHAR(50) DEFAULT '无',
  join_date DATE DEFAULT CURRENT_DATE,
  total_hours DECIMAL(8,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT '正常',
  notes TEXT DEFAULT ''
);

-- 2. 活动表
CREATE TABLE IF NOT EXISTS activities (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  type VARCHAR(50),
  description TEXT,
  location VARCHAR(200),
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  max_participants INTEGER DEFAULT 0,
  current_participants INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT '筹备中',
  creator_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. 报名明细表
CREATE TABLE IF NOT EXISTS signups (
  id BIGSERIAL PRIMARY KEY,
  activity_id BIGINT REFERENCES activities(id) ON DELETE CASCADE,
  member_id BIGINT REFERENCES members(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  signup_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(20) DEFAULT '已报名',
  hours DECIMAL(8,2) DEFAULT 0,
  notes TEXT DEFAULT ''
);

-- 4. 公告表
CREATE TABLE IF NOT EXISTS announcements (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  content TEXT,
  type VARCHAR(50),
  status VARCHAR(20) DEFAULT '发布',
  creator_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  pinned BOOLEAN DEFAULT false
);

-- 5. 权限配置表（7级角色）
CREATE TABLE IF NOT EXISTS permissions (
  id SERIAL PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,
  level INTEGER NOT NULL,
  member_mgmt VARCHAR(20) DEFAULT '否',
  activity_mgmt VARCHAR(20) DEFAULT '否',
  hours_mgmt VARCHAR(20) DEFAULT '否',
  announce_mgmt VARCHAR(20) DEFAULT '否',
  signup_mgmt VARCHAR(20) DEFAULT '否',
  view_members VARCHAR(20) DEFAULT '是',
  view_activities VARCHAR(20) DEFAULT '是',
  view_announcements VARCHAR(20) DEFAULT '是',
  view_hours VARCHAR(20) DEFAULT '是'
);

-- 6. 自动更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 时间戳触发器
CREATE TRIGGER members_updated BEFORE UPDATE ON members FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER activities_updated BEFORE UPDATE ON activities FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER signups_updated BEFORE UPDATE ON signups FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER announcements_updated BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 7. 插入默认权限数据
INSERT INTO permissions (role_name, level, member_mgmt, activity_mgmt, hours_mgmt, announce_mgmt, signup_mgmt, view_members, view_activities, view_announcements, view_hours) VALUES
('老师', 7, '完全', '完全', '完全', '完全', '完全', '是', '是', '是', '是'),
('主席', 6, '完全', '完全', '完全', '完全', '完全', '是', '是', '是', '是'),
('副主席', 5, '完全', '完全', '完全', '完全', '完全', '是', '是', '是', '是'),
('会长', 4, '只读', '完全', '完全', '完全', '完全', '是', '是', '是', '是'),
('副会长', 3, '只读', '完全', '完全', '完全', '完全', '是', '是', '是', '是'),
('会员', 2, '否', '否', '否', '否', '否', '是', '是', '是', '是'),
('志愿者', 1, '否', '否', '否', '否', '否', '否', '否', '是', '仅个人')
ON CONFLICT (role_name) DO NOTHING;

-- 8. RLS 策略（行级安全）
ALTER TABLE members ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE signups ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;

-- members: 所有登录用户可读，只有自己或管理员可修改
CREATE POLICY "Members read for authenticated" ON members
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Members insert for authenticated" ON members
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Members update for authenticated" ON members
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Members delete for admin" ON members
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- activities: 所有登录用户可读可写
CREATE POLICY "Activities read for authenticated" ON activities
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Activities insert for authenticated" ON activities
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Activities update for authenticated" ON activities
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Activities delete for authenticated" ON activities
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- signups: 所有登录用户可读可写
CREATE POLICY "Signups read for authenticated" ON signups
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Signups insert for authenticated" ON signups
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Signups update for authenticated" ON signups
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Signups delete for authenticated" ON signups
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- announcements: 所有登录用户可读可写
CREATE POLICY "Announcements read for authenticated" ON announcements
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Announcements insert for authenticated" ON announcements
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Announcements update for authenticated" ON announcements
  FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Announcements delete for authenticated" ON announcements
  FOR DELETE USING (auth.uid() IS NOT NULL);

-- permissions: 所有登录用户可读
CREATE POLICY "Permissions read for authenticated" ON permissions
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- 9. 创建用于获取当前用户角色信息的视图
CREATE OR REPLACE VIEW user_roles AS
SELECT 
  m.id AS member_id,
  m.user_id,
  m.name,
  m.role,
  p.level,
  p.member_mgmt,
  p.activity_mgmt,
  p.hours_mgmt,
  p.announce_mgmt,
  p.signup_mgmt,
  p.view_members,
  p.view_activities,
  p.view_announcements,
  p.view_hours
FROM members m
LEFT JOIN permissions p ON m.role = p.role_name;

-- 10. 为 user_roles 视图创建可更新的规则（Supabase需要）
GRANT SELECT ON user_roles TO authenticated;
