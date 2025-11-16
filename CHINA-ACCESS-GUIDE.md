# 中国大陆访问配置指南

## 📋 问题说明

**现象：**
- ✅ 使用境外代理可以访问 `https://api-key-management.161105069.workers.dev`
- ❌ 中国大陆网络直接访问超时或无法连接

**原因：**
- `*.workers.dev` 域名在中国大陆网络环境下访问受限
- Cloudflare 的 Anycast IP 可能被 DNS 污染或网络策略限制
- 部分网络运营商对该域名有特殊的网络策略

---

## ✅ 解决方案对比

| 方案 | 难度 | 成本 | 稳定性 | 速度 | 备案要求 |
|------|------|------|--------|------|----------|
| 自定义域名（推荐） | ⭐ 低 | 💰 免费 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 建议备案 |
| Cloudflare China | ⭐⭐⭐ 高 | 💰💰💰 付费 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 必须备案 |
| 第三方 CDN | ⭐⭐ 中 | 💰💰 低费用 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 必须备案 |
| 境外代理 | ⭐ 低 | 💰 免费-低费用 | ⭐⭐ | ⭐⭐ | 不需要 |

---

## 🌟 方案一：绑定自定义域名（强烈推荐）

### **优点**
- ✅ 完全绕过 `workers.dev` 限制
- ✅ 配置简单，5分钟完成
- ✅ 完全免费
- ✅ 自动配置 SSL 证书
- ✅ 使用自己的品牌域名

### **步骤详解**

#### **1️⃣ 准备域名**
你需要拥有一个域名（如从阿里云、腾讯云、GoDaddy 等购买）

**注意：**
- 如果域名已备案 → 中国访问完全稳定
- 如果域名未备案 → 可能被部分网络限制，但比 workers.dev 稳定得多

#### **2️⃣ 将域名托管到 Cloudflare**

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 点击 **Add a Site**
3. 输入你的域名（如 `example.com`）
4. 选择 **Free** 计划
5. Cloudflare 会显示两个 DNS 服务器地址，如：
   ```
   ns1.cloudflare.com
   ns2.cloudflare.com
   ```
6. 到你的域名注册商（阿里云/腾讯云等）修改 DNS 服务器：
   - 阿里云：控制台 → 域名 → 管理 → DNS 修改
   - 腾讯云：控制台 → 域名管理 → DNS 修改
7. 等待 DNS 生效（通常 5-30 分钟）

#### **3️⃣ 方式A：通过 Dashboard 绑定（推荐新手）**

1. 进入 **Workers & Pages** → **api-key-management**
2. 点击 **Settings** 标签
3. 点击 **Triggers** → **Custom Domains**
4. 点击 **Add Custom Domain**
5. 输入子域名，例如：`api.example.com`
6. 点击 **Add Custom Domain**
7. Cloudflare 会自动：
   - 创建 DNS 记录
   - 配置 SSL 证书
   - 绑定到 Worker

#### **4️⃣ 方式B：通过 wrangler.toml 配置（推荐开发者）**

编辑 `wrangler.toml`：

```toml
# 取消注释并修改以下部分
[[routes]]
pattern = "api.example.com/*"
zone_name = "example.com"
```

然后重新部署：
```bash
wrangler deploy
```

#### **5️⃣ 测试访问**

**在中国网络环境下测试：**
```bash
# 替换为你的域名
curl -X POST https://api.example.com/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**预期成功响应：**
```json
{
  "success": true,
  "token": "eyJhbGci..."
}
```

#### **6️⃣ DNS 传播检查**

检查域名是否全球生效：
```bash
# Linux/Mac
nslookup api.example.com

# 或使用在线工具
# https://dnschecker.org
```

---

## 🏢 方案二：Cloudflare China Network（企业方案）

### **适用场景**
- 企业级应用
- 需要最佳中国访问性能
- 有备案域名
- 预算充足

### **特点**
- ✅ 中国大陆直连节点（与百度云加速合作）
- ✅ 超低延迟（<50ms）
- ✅ 完全合规
- ❌ 需要企业认证
- ❌ 需要付费（具体价格联系销售）
- ❌ 必须 ICP 备案

### **申请流程**
1. 访问：https://www.cloudflare.com/zh-cn/china-network/
2. 点击 **联系销售**
3. 提交企业信息和备案证明
4. 等待审核和签约

---

## 🚀 方案三：第三方 CDN 加速

### **架构**
```
中国用户 → 腾讯云CDN/阿里云CDN → Cloudflare Worker（境外）
```

### **步骤**

#### **1️⃣ 准备自定义域名**
按照方案一先绑定自定义域名到 Worker

#### **2️⃣ 购买国内 CDN**
- **腾讯云 CDN**：https://cloud.tencent.com/product/cdn
- **阿里云 CDN**：https://www.aliyun.com/product/cdn

#### **3️⃣ 配置 CDN**
1. 添加加速域名（如 `cdn.example.com`）
2. 源站类型选择：**自有源站**
3. 源站地址填写：`api.example.com`（你的 Worker 自定义域名）
4. 回源协议：**HTTPS**
5. 提交备案（CDN 域名需要备案）

#### **4️⃣ 配置 CNAME**
在 DNS 中添加 CNAME 记录：
```
cdn.example.com → [CDN提供的CNAME地址]
```

#### **5️⃣ 测试**
```bash
curl -X POST https://cdn.example.com/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### **成本估算**
- 腾讯云 CDN：¥0.20/GB 起（按流量计费）
- 阿里云 CDN：¥0.24/GB 起
- 月流量 100GB → 约 ¥20-30/月

---

## 🔧 方案四：临时方案（开发测试用）

### **使用公共代理服务**

**免费方案：**
1. **Cloudflare WARP**（推荐）
   - 下载：https://1.1.1.1
   - 免费版本即可使用
   - 速度较快

2. **v2rayN / Clash**
   - 需要自己配置节点
   - 适合开发测试

**注意：** 此方案仅适合开发测试，**不推荐生产环境使用**！

---

## 📊 推荐方案选择

### **个人项目 / 小型应用**
→ **方案一：自定义域名**
- 成本：免费
- 时间：5分钟
- 效果：80% 用户可正常访问

### **商业应用 / 中型项目**
→ **方案一 + 方案三：自定义域名 + CDN**
- 成本：¥20-100/月
- 时间：1-2小时
- 效果：99% 用户稳定访问

### **企业级应用**
→ **方案二：Cloudflare China Network**
- 成本：按需定价
- 时间：1-2周（审核+配置）
- 效果：100% 用户高速访问

---

## 🛠️ 故障排查

### **1. 绑定自定义域名后仍无法访问**

**检查 DNS 解析：**
```bash
nslookup api.example.com
```

如果返回 `workers.dev` 相关 IP，说明 DNS 未生效，等待更长时间。

**检查 SSL 证书：**
```bash
curl -v https://api.example.com
```

查看证书是否由 Cloudflare 签发。

### **2. 访问速度慢**

- **原因：** 未使用中国 CDN，流量需要绕道境外
- **解决：** 添加腾讯云/阿里云 CDN（方案三）

### **3. 部分地区仍无法访问**

- **原因：** 个别网络运营商策略
- **解决：**
  1. 确保域名已备案
  2. 使用 CDN 加速
  3. 联系运营商客服

---

## 📚 相关文档

- [Cloudflare Workers 文档](https://developers.cloudflare.com/workers/)
- [自定义域名配置](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)
- [腾讯云 CDN 文档](https://cloud.tencent.com/document/product/228)
- [ICP 备案指南](https://beian.miit.gov.cn/)

---

## ❓ 常见问题

**Q1: 必须备案才能在中国访问吗？**
A: 不一定。未备案域名也能访问，但稳定性较差。建议备案以获得最佳体验。

**Q2: 绑定自定义域名需要多久？**
A: Dashboard 操作 2 分钟，DNS 全球生效 5-30 分钟。

**Q3: 使用自定义域名会影响功能吗？**
A: 不会。功能完全一样，只是更换了访问地址。

**Q4: 可以同时使用多个域名吗？**
A: 可以。在 Dashboard 添加多个 Custom Domains 即可。

**Q5: 自定义域名免费吗？**
A: Cloudflare 的自定义域名绑定完全免费，包括 SSL 证书。你只需支付域名注册费用（通常 ¥50-100/年）。

---

## 📞 技术支持

如果遇到问题：
1. 检查本文档的故障排查部分
2. 查看 Cloudflare 官方文档
3. 提交 GitHub Issue
4. 联系 Cloudflare 支持（付费用户）
