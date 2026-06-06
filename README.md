# 城建青协 · 志愿者管理系统 v2

文华学院城市建设学部青年志愿者协会全功能管理系统。

## 架构

```
Supabase (Auth + PostgreSQL + Realtime)  <-->  前端 SPA (GitHub Pages)
```

- **用户认证**: Supabase Auth（邮箱+密码）
- **数据存储**: Supabase PostgreSQL
- **实时同步**: Supabase Realtime（WebSocket）
- **前端**: 纯静态 HTML/CSS/JS，暗色 Supabase 风格
- **部署**: GitHub Pages

## 功能

- 登录 / 注册（自动创建成员记录）
- 数据总览（统计卡片 + 图表）
- 成员管理（增删改查）
- 活动管理（发布 / 编辑 / 取消）
- 报名管理（查看 / 录入时长）
- 时长统计（排行榜 + 图表）
- 公告管理（发布 / 编辑 / 置顶 / 归档）
- 7级角色权限控制

## 部署步骤

### 1. Supabase 建表

1. 打开 Supabase Dashboard
2. 进入 SQL Editor → New Query
3. 粘贴 `supabase-schema.sql` 的全部内容 → Run
4. Authentication → Providers → 确保 Email 已开启
5. Authentication → Settings → 关闭 Email Confirmations（可选，方便测试）

### 2. 部署前端

```bash
# 在 GitHub 创建空仓库 qingxie-v2
git init
git add index.html supabase-schema.sql README.md
git commit -m "初始部署"
git branch -M main
git remote add origin https://github.com/你的用户名/qingxie-v2.git
git push -u origin main
```

### 3. 开启 GitHub Pages

仓库 Settings → Pages → Source: main 分支 → Save

访问: `https://你的用户名.github.io/qingxie-v2/`

## 文件说明

| 文件 | 说明 |
|------|------|
| `index.html` | 完整前端系统（单文件 SPA） |
| `supabase-schema.sql` | Supabase 建表 SQL |
| `README.md` | 项目说明 |
