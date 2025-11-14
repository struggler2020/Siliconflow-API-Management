# ⚡ 快速开始指南

从零到部署完成仅需 **15分钟**！

---

## 📋 前提条件

- ✅ Cloudflare账号（免费）
- ✅ 浏览器
- ✅ 本项目文件

---

## 🚀 5步部署流程

### 第1步：创建D1数据库（2分钟）

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 左侧菜单选择 **Workers & Pages**
3. 点击顶部 **D1** 标签
4. 点击 **创建数据库**
5. 输入数据库名称：`api_key_management_db`
6. 点击 **创建**

✅ **记录数据库ID**（后续需要）

---

### 第2步：初始化数据库（3分钟）

1. 点击刚创建的数据库名称
2. 点击 **Console** 标签
3. 打开 `database-schema.sql` 文件
4. **复制全部内容**
5. 粘贴到控制台
6. 点击 **Execute**

✅ 看到 `Database initialized successfully!` 表示成功

---

### 第3步：部署Worker（5分钟）

1. 返回 **Workers & Pages** 主页
2. 点击 **Create Application**
3. 选择 **Create Worker**
4. 输入名称：`api-key-management`
5. 点击 **Deploy**
6. 部署后点击 **Edit code**
7. **删除所有默认代码**
8. 打开 `worker-backend.js` 文件
9. **复制全部内容**
10. 粘贴到编辑器
11. 点击 **Save and Deploy**

✅ Worker已部署

---

### 第4步：绑定数据库（2分钟）

1. 点击 **Settings** 标签
2. 找到 **Bindings** 部分
3. 点击 **Add**
4. 选择 **D1 Database**
5. 配置：
   - Variable name: `db`
   - D1 database: 选择 `api_key_management_db`
6. 点击 **Save**
7. 返回 **Code** 标签
8. 点击 **Save and Deploy** 重新部署

✅ 数据库已绑定

---

### 第5步：测试验证（3分钟）

复制您的Worker URL（类似 `https://api-key-management.YOUR_SUBDOMAIN.workers.dev`）

#### 测试管理员登录

```bash
curl -X POST https://YOUR_WORKER_URL/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**预期响应：**
```json
{
  "success": true,
  "token": "eyJhbGc..."
}
```

✅ 如果收到token，部署成功！

---

## 🎉 部署完成！

您的API密钥配额验证系统已上线！

**Worker URL:**
```
https://YOUR_WORKER_URL
```

---

## 📝 下一步操作

### 1. 修改默认密码（必须）

**方法A：通过D1控制台**

进入数据库Console，执行：
```sql
-- 生成新密码哈希（示例：使用在线SHA-256工具）
UPDATE admins
SET password_hash = '您的新密码哈希值'
WHERE username = 'admin';
```

**方法B：创建新管理员**

使用API创建（需要先用默认账号登录获取token）

### 2. 创建第一个租户

```bash
# 使用上面获取的admin token
export ADMIN_TOKEN="your_token_here"

curl -X POST https://YOUR_WORKER_URL/api/admin/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "我的第一个租户",
    "username": "tenant1",
    "password": "your_secure_password",
    "maxProducts": 10,
    "maxApiKeys": 100,
    "maxCodesPerProduct": 1000
  }'
```

### 3. 租户登录并生成API密钥

```bash
# 租户登录
curl -X POST https://YOUR_WORKER_URL/api/tenant/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tenant1",
    "password": "your_secure_password"
  }'

# 保存返回的token
export TENANT_TOKEN="tenant_token_here"

# 生成API密钥
curl -X POST https://YOUR_WORKER_URL/api/tenant/keys \
  -H "Authorization: Bearer $TENANT_TOKEN"
```

### 4. 创建商品并生成兑换码

```bash
# 创建商品
curl -X POST https://YOUR_WORKER_URL/api/tenant/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "测试商品",
    "description": "测试商品描述",
    "defaultCalls": 100,
    "defaultDays": 30,
    "category": "test"
  }'

# 保存返回的productId
export PRODUCT_ID="prod_xxxx..."

# 生成兑换码
curl -X POST https://YOUR_WORKER_URL/api/tenant/products/$PRODUCT_ID/codes/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "count": 10,
    "expiryDays": 30
  }'
```

---

## 🧪 完整测试流程

参考 [API-EXAMPLES.md](./API-EXAMPLES.md) 中的完整测试脚本：

```bash
# 下载测试脚本
# 编辑 API_BASE_URL 为您的Worker URL
# 执行测试
bash test-api.sh
```

---

## 📚 更多文档

- **详细部署文档**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **API使用示例**: [API-EXAMPLES.md](./API-EXAMPLES.md)
- **项目介绍**: [README-NEW-SYSTEM.md](./README-NEW-SYSTEM.md)

---

## ❓ 遇到问题？

### 常见问题速查

**Q: 登录返回401**
- 检查用户名和密码是否正确（默认：admin/admin123）
- 确认数据库已正确初始化

**Q: 验证接口返回404**
- 确认D1数据库已绑定
- 确认变量名为 `db`
- 重新部署Worker

**Q: 请求CORS错误**
- 确认Worker代码完整复制
- 检查请求头是否包含 `Content-Type: application/json`

### 查看日志

1. 进入Worker详情页面
2. 点击 **Logs** 标签
3. 点击 **Begin log stream**
4. 发送请求查看实时日志

---

## 🎯 配置自定义域名（可选）

1. 进入Worker详情页面
2. 点击 **Triggers** 标签
3. 在 **Custom Domains** 点击 **Add Custom Domain**
4. 输入域名（如 `api.yourdomain.com`）
5. 等待5-10分钟DNS生效

---

## 🔐 安全检查清单

部署完成后，请确保：

- [ ] 已修改默认管理员密码
- [ ] 已修改JWT密钥（代码中 `CONFIG.JWT_SECRET`）
- [ ] 已测试所有核心功能
- [ ] 已配置定期备份（可选）
- [ ] 已限制管理员账号数量（可选）

---

## 💡 使用提示

### 租户使用流程

```
1. 租户登录 → 获取token
2. 生成API密钥 → 分发给用户
3. 创建商品 → 定义配额
4. 生成兑换码 → 售卖或分发
5. 查看统计 → 监控使用情况
```

### 用户使用流程

```
1. 获得API密钥（从租户）
2. 使用API密钥登录 → 激活账号
3. 获得兑换码（购买或领取）
4. 兑换兑换码 → 激活产品
5. 使用商品 → 自动扣减配额
```

### 商品集成流程

```
1. 获得商品ID（租户提供）
2. 在商品代码中硬编码 PRODUCT_ID
3. 用户访问时，调用 /api/verify 验证
4. 根据验证结果决定是否允许访问
5. 每次验证自动扣减1次配额
```

---

## 📊 系统容量

### 免费额度

- **Worker请求**: 10万次/天
- **D1读取**: 500万次/天
- **D1写入**: 10万次/天
- **D1存储**: 500MB

### 适用规模

- **小规模**: < 1万次验证/天 → 完全免费 ✅
- **中等规模**: 1-10万次/天 → 完全免费 ✅
- **大规模**: > 10万次/天 → 需要升级付费计划

---

## 🚀 性能指标

- **验证接口响应**: < 10ms
- **管理操作响应**: < 50ms
- **全球访问延迟**: 10-100ms（Cloudflare边缘网络）
- **并发能力**: 无限（Cloudflare Workers自动扩展）

---

**恭喜您完成部署！开始使用吧 🎉**

如有问题，请参考 [DEPLOYMENT.md](./DEPLOYMENT.md) 的详细文档。
