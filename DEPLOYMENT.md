# 🚀 API密钥配额验证系统 - 部署操作文档

## 📋 目录

1. [准备工作](#准备工作)
2. [创建D1数据库](#创建d1数据库)
3. [初始化数据库](#初始化数据库)
4. [部署Worker](#部署worker)
5. [配置自定义域名](#配置自定义域名可选)
6. [初始化管理员账号](#初始化管理员账号)
7. [测试验证](#测试验证)
8. [常见问题](#常见问题)

---

## 准备工作

### 1. 账号准备

- ✅ Cloudflare账号（[注册地址](https://dash.cloudflare.com/sign-up)）
- ✅ 确认账号已登录

### 2. 文件准备

确保您有以下文件：
```
api-key-management/
├── database-schema.sql      # 数据库初始化脚本
├── worker-backend.js        # Worker后端代码
└── DEPLOYMENT.md           # 本文档
```

---

## 创建D1数据库

### 步骤1: 进入D1管理页面

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 在左侧导航栏选择 **"Workers & Pages"**
3. 点击顶部的 **"D1"** 标签

### 步骤2: 创建数据库

1. 点击 **"创建数据库"** 按钮
2. 填写数据库信息：
   - **数据库名称**: `api_key_management_db`（或您喜欢的名称）
   - **位置**: 选择最近的区域（如 `自动`）
3. 点击 **"创建"** 按钮

### 步骤3: 记录数据库ID

创建成功后，您会看到数据库详情页面，记录下：
- **数据库名称**: `api_key_management_db`
- **数据库ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

---

## 初始化数据库

### 步骤1: 进入数据库查询界面

1. 在D1数据库列表中，点击刚创建的数据库名称
2. 点击顶部的 **"Console"** 或 **"查询"** 标签

### 步骤2: 执行初始化脚本

1. 打开 `database-schema.sql` 文件
2. **复制所有SQL代码**
3. 粘贴到D1查询控制台中
4. 点击 **"Execute"** 或 **"执行"** 按钮

### 步骤3: 验证初始化结果

执行成功后，您应该看到：
```
Database initialized successfully!
```

点击 **"Tables"** 标签，确认以下表已创建：
- ✅ admins
- ✅ tenants
- ✅ tenant_accounts
- ✅ api_keys
- ✅ users
- ✅ products
- ✅ redemption_codes
- ✅ key_quotas
- ✅ config

---

## 部署Worker

### 方法A: 通过Cloudflare Dashboard部署（推荐）

#### 步骤1: 创建Worker

1. 返回 **"Workers & Pages"** 主页
2. 点击 **"Create Application"** 或 **"创建应用程序"**
3. 选择 **"Create Worker"**
4. 填写Worker名称：`api-key-management`
5. 点击 **"Deploy"** 或 **"部署"**

#### 步骤2: 编辑Worker代码

1. 部署成功后，点击 **"Edit code"** 或 **"编辑代码"**
2. **删除所有默认代码**
3. 打开 `worker-backend.js` 文件
4. **复制所有代码**
5. 粘贴到Worker编辑器中
6. 点击右上角 **"Save and Deploy"** 或 **"保存并部署"**

#### 步骤3: 绑定D1数据库

1. 点击 **"Settings"** 或 **"设置"** 标签
2. 滚动到 **"Bindings"** 或 **"变量和机密"** 部分
3. 点击 **"Add"** 或 **"添加"** 按钮
4. 选择 **"D1 Database"**
5. 配置绑定：
   - **Variable name**: `db`（必须是`db`）
   - **D1 database**: 选择之前创建的 `api_key_management_db`
6. 点击 **"Save"** 或 **"保存"**

#### 步骤4: 重新部署

绑定D1后，Worker需要重新部署：
1. 返回 **"Code"** 或 **"代码"** 标签
2. 点击 **"Save and Deploy"** 或 **"保存并部署"**

### 方法B: 通过Wrangler CLI部署（高级）

#### 步骤1: 安装Wrangler

```bash
npm install -g wrangler
```

#### 步骤2: 登录Cloudflare

```bash
wrangler login
```

#### 步骤3: 创建wrangler.toml配置文件

```toml
name = "api-key-management"
main = "worker-backend.js"
compatibility_date = "2024-01-01"

[[d1_databases]]
binding = "db"
database_name = "api_key_management_db"
database_id = "YOUR_DATABASE_ID_HERE"
```

**注意**: 将 `YOUR_DATABASE_ID_HERE` 替换为您的实际数据库ID

#### 步骤4: 部署

```bash
wrangler deploy
```

---

## 配置自定义域名（可选）

### 步骤1: 添加域名到Cloudflare

如果您的域名不在Cloudflare，需要先添加：
1. 在Cloudflare Dashboard中，点击 **"Add a Site"**
2. 输入您的域名，点击 **"Add Site"**
3. 按照指引修改域名的DNS服务器

### 步骤2: 为Worker绑定自定义域名

1. 进入您的Worker详情页面
2. 点击 **"Triggers"** 或 **"触发器"** 标签
3. 在 **"Custom Domains"** 部分，点击 **"Add Custom Domain"**
4. 输入您的域名或子域名，例如：`api.yourdomain.com`
5. 点击 **"Add Custom Domain"**
6. Cloudflare会自动配置DNS记录

### 步骤3: 等待DNS生效

- 通常需要5-10分钟
- 您可以通过浏览器访问 `https://api.yourdomain.com` 测试

---

## 初始化管理员账号

### 默认管理员账号

系统已在数据库初始化时创建默认管理员账号：
- **用户名**: `admin`
- **密码**: `admin123`

⚠️ **重要安全提示**: 请在首次登录后立即修改密码！

### 修改管理员密码（通过D1控制台）

1. 进入D1数据库查询控制台
2. 执行以下SQL修改密码：

```sql
-- 生成新密码的哈希值（示例：newpassword123）
-- 注意：这是简化的哈希，生产环境建议使用bcrypt

-- 更新管理员密码
UPDATE admins
SET password_hash = '您的新密码哈希值'
WHERE username = 'admin';
```

### 创建新管理员（通过D1控制台）

```sql
INSERT INTO admins (id, username, password_hash, created_at)
VALUES (
  'admin_' || hex(randomblob(16)),
  'newadmin',
  '新密码的哈希值',
  datetime('now')
);
```

---

## 测试验证

### 1. 测试Worker基本访问

浏览器访问您的Worker地址：
```
https://api-key-management.YOUR_SUBDOMAIN.workers.dev
```

或自定义域名：
```
https://api.yourdomain.com
```

### 2. 测试管理员登录

使用API测试工具（如Postman、curl）测试：

```bash
curl -X POST https://YOUR_WORKER_URL/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**预期响应：**
```json
{
  "success": true,
  "token": "eyJhbGc..."
}
```

### 3. 测试创建租户

使用上一步获得的token：

```bash
curl -X POST https://YOUR_WORKER_URL/api/admin/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "name": "测试租户",
    "username": "tenant1",
    "password": "tenant123",
    "maxProducts": 10,
    "maxApiKeys": 100,
    "maxCodesPerProduct": 1000
  }'
```

**预期响应：**
```json
{
  "success": true,
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "username": "tenant1"
}
```

### 4. 测试租户登录

```bash
curl -X POST https://YOUR_WORKER_URL/api/tenant/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tenant1",
    "password": "tenant123"
  }'
```

### 5. 测试核心验证接口

```bash
curl -X POST https://YOUR_WORKER_URL/api/verify \
  -H "Content-Type: application/json" \
  -d '{
    "key": "sk_test_xxxx",
    "product": "prod_xxxx"
  }'
```

**预期响应（无权限时）：**
```json
{
  "valid": false,
  "remaining": 0,
  "message": "API密钥不存在"
}
```

---

## 常见问题

### Q1: 数据库初始化失败

**错误**: `table already exists`

**解决方案**:
1. 检查是否已经初始化过
2. 如需重新初始化，先删除所有表：

```sql
DROP TABLE IF EXISTS key_quotas;
DROP TABLE IF EXISTS redemption_codes;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS api_keys;
DROP TABLE IF EXISTS tenant_accounts;
DROP TABLE IF EXISTS tenants;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS config;
```

然后重新执行初始化脚本。

### Q2: Worker部署后访问404

**可能原因**:
1. D1数据库未正确绑定
2. 变量名不是`db`

**解决方案**:
1. 检查Settings → Bindings
2. 确认变量名为`db`
3. 确认选择了正确的数据库
4. 重新部署Worker

### Q3: 登录返回401错误

**可能原因**:
1. 用户名或密码错误
2. 管理员账号未正确初始化

**解决方案**:
1. 确认使用默认账号：`admin` / `admin123`
2. 检查D1中admins表是否有数据：

```sql
SELECT * FROM admins;
```

### Q4: CORS错误

**错误**: `Access to fetch at ... has been blocked by CORS policy`

**解决方案**:
代码中已包含CORS头，确保：
1. Worker代码完整复制
2. 请求包含正确的Content-Type头

### Q5: 验证接口返回错误

**错误**: `API密钥不存在`

**原因**: 需要先通过租户生成API密钥

**解决方案**:
完整流程：
1. 管理员创建租户
2. 租户登录
3. 租户生成API密钥
4. 租户创建商品
5. 租户生成兑换码
6. 用户使用API密钥登录
7. 用户兑换码
8. 测试验证接口

### Q6: 如何查看Worker日志

1. 进入Worker详情页面
2. 点击 **"Logs"** 或 **"日志"** 标签
3. 选择 **"Begin log stream"** 开始实时查看

### Q7: 如何备份数据

定期导出D1数据库：

```bash
# 使用Wrangler CLI
wrangler d1 export api_key_management_db --output backup.sql
```

或通过控制台手动导出关键数据：

```sql
-- 导出所有租户
SELECT * FROM tenants;

-- 导出所有API密钥
SELECT * FROM api_keys;

-- 导出所有商品
SELECT * FROM products;
```

---

## 🎉 部署完成检查清单

- [ ] D1数据库已创建
- [ ] 数据库已初始化（9张表）
- [ ] Worker已部署
- [ ] D1已绑定到Worker
- [ ] 管理员登录测试通过
- [ ] 创建测试租户成功
- [ ] 租户登录测试通过
- [ ] （可选）自定义域名已配置
- [ ] （必须）默认密码已修改

---

## 📞 获取帮助

如遇到问题：
1. 查看Worker日志
2. 检查D1数据库数据
3. 参考本文档常见问题部分
4. 查看Cloudflare官方文档

---

## 🔐 安全建议

### 生产环境部署前必做：

1. ✅ **修改默认管理员密码**
2. ✅ **修改JWT密钥**：在代码中修改 `CONFIG.JWT_SECRET`
3. ✅ **启用HTTPS**：Cloudflare Worker自动提供
4. ✅ **定期备份数据**：使用Wrangler CLI导出
5. ✅ **监控日志**：定期检查异常访问
6. ✅ **限制管理员访问**：仅在必要时使用管理员账号

---

## 📈 下一步

部署完成后，您可以：

1. **开发前端界面**：使用提供的API端点构建管理界面
2. **集成到现有系统**：将验证接口集成到您的商品/应用中
3. **自定义扩展**：根据业务需求添加新功能
4. **性能优化**：根据实际使用情况调整配额同步频率

---

**祝您部署顺利！🚀**
