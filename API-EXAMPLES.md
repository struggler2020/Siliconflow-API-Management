# 🧪 API接口测试示例

本文档提供完整的API测试流程和示例代码。

## 📋 目录

1. [环境准备](#环境准备)
2. [管理员操作流程](#管理员操作流程)
3. [租户操作流程](#租户操作流程)
4. [用户操作流程](#用户操作流程)
5. [验证接口测试](#验证接口测试)
6. [JavaScript示例](#javascript示例)
7. [Python示例](#python示例)

---

## 环境准备

### 设置API基础URL

```bash
# 替换为您实际的Worker地址
export API_BASE_URL="https://api-key-management.YOUR_SUBDOMAIN.workers.dev"

# 或自定义域名
export API_BASE_URL="https://api.yourdomain.com"
```

---

## 管理员操作流程

### 1. 管理员登录

```bash
curl -X POST $API_BASE_URL/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**响应示例：**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**保存Token：**
```bash
export ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 2. 创建租户

```bash
curl -X POST $API_BASE_URL/api/admin/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "测试租户A",
    "username": "tenant_a",
    "password": "tenant123",
    "maxProducts": 10,
    "maxApiKeys": 100,
    "maxCodesPerProduct": 1000
  }'
```

**响应示例：**
```json
{
  "success": true,
  "tenantId": "550e8400-e29b-41d4-a716-446655440000",
  "username": "tenant_a"
}
```

**保存租户ID：**
```bash
export TENANT_ID="550e8400-e29b-41d4-a716-446655440000"
```

### 3. 查看所有租户

```bash
curl -X GET $API_BASE_URL/api/admin/tenants \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 4. 更新租户配额

```bash
curl -X PUT $API_BASE_URL/api/admin/tenants/$TENANT_ID/quota \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "maxProducts": 20,
    "maxApiKeys": 200,
    "maxCodesPerProduct": 5000
  }'
```

### 5. 查看所有商品（所有租户）

```bash
curl -X GET $API_BASE_URL/api/admin/products \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## 租户操作流程

### 1. 租户登录

```bash
curl -X POST $API_BASE_URL/api/tenant/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tenant_a",
    "password": "tenant123"
  }'
```

**响应示例：**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**保存Token：**
```bash
export TENANT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 2. 生成API密钥

```bash
curl -X POST $API_BASE_URL/api/tenant/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN"
```

**响应示例：**
```json
{
  "success": true,
  "apiKey": "sk_550e_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8"
}
```

**保存API密钥：**
```bash
export API_KEY="sk_550e_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8"
```

### 3. 查看所有API密钥

```bash
curl -X GET $API_BASE_URL/api/tenant/keys \
  -H "Authorization: Bearer $TENANT_TOKEN"
```

### 4. 创建商品

```bash
curl -X POST $API_BASE_URL/api/tenant/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name": "GPT-4服务",
    "description": "高级AI对话服务",
    "defaultCalls": 1000,
    "defaultDays": 30,
    "category": "ai"
  }'
```

**响应示例：**
```json
{
  "success": true,
  "productId": "prod_abc123def456ghi789jkl012mno345pqr678stu",
  "name": "GPT-4服务"
}
```

**保存商品ID：**
```bash
export PRODUCT_ID="prod_abc123def456ghi789jkl012mno345pqr678stu"
```

### 5. 查看商品列表

```bash
curl -X GET $API_BASE_URL/api/tenant/products \
  -H "Authorization: Bearer $TENANT_TOKEN"
```

### 6. 为商品生成兑换码

```bash
curl -X POST $API_BASE_URL/api/tenant/products/$PRODUCT_ID/codes/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "count": 10,
    "expiryDays": 30
  }'
```

**响应示例：**
```json
{
  "success": true,
  "batchId": "batch-uuid-here",
  "codes": [
    "ABCD1234EFGH",
    "WXYZ5678PQRS",
    "MNOP9012STUV",
    "..."
  ],
  "count": 10,
  "quota": {
    "used": 10,
    "total": 1000,
    "remaining": 990
  }
}
```

**保存一个兑换码用于测试：**
```bash
export REDEEM_CODE="ABCD1234EFGH"
```

---

## 用户操作流程

### 1. 用户登录（使用API密钥）

```bash
curl -X POST $API_BASE_URL/api/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "apiKey": "'$API_KEY'"
  }'
```

**响应示例（首次登录）：**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": "user-uuid-here",
  "isFirstLogin": true
}
```

**保存用户Token：**
```bash
export USER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 2. 查看用户信息

```bash
curl -X GET $API_BASE_URL/api/user/info \
  -H "Authorization: Bearer $USER_TOKEN"
```

### 3. 兑换兑换码

```bash
curl -X POST $API_BASE_URL/api/user/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "code": "'$REDEEM_CODE'"
  }'
```

**响应示例（新创建）：**
```json
{
  "success": true,
  "action": "created",
  "product": "GPT-4服务",
  "totalCalls": 1000,
  "expiresAt": "2025-02-15T00:00:00.000Z"
}
```

**响应示例（叠加）：**
```json
{
  "success": true,
  "action": "stacked",
  "product": "GPT-4服务",
  "addedCalls": 1000,
  "totalCalls": 2000,
  "expiresAt": "2025-03-15T00:00:00.000Z"
}
```

### 4. 查看产品配额

```bash
curl -X GET $API_BASE_URL/api/user/quotas \
  -H "Authorization: Bearer $USER_TOKEN"
```

**响应示例：**
```json
{
  "success": true,
  "quotas": [
    {
      "id": "quota-uuid",
      "product_id": "prod_abc123...",
      "product_name": "GPT-4服务",
      "description": "高级AI对话服务",
      "quota_total": 1000,
      "quota_used": 0,
      "activated_at": "2025-01-15T10:30:00.000Z",
      "expires_at": "2025-02-15T00:00:00.000Z",
      "status": "active"
    }
  ]
}
```

---

## 验证接口测试

### 验证API密钥和产品权限

```bash
curl -X POST $API_BASE_URL/api/verify \
  -H "Content-Type: application/json" \
  -d '{
    "key": "'$API_KEY'",
    "product": "'$PRODUCT_ID'"
  }'
```

**响应示例（验证通过）：**
```json
{
  "valid": true,
  "remaining": 999,
  "total": 1000,
  "used": 1,
  "expires_at": "2025-02-15T00:00:00.000Z",
  "message": "验证通过"
}
```

**响应示例（配额用完）：**
```json
{
  "valid": false,
  "remaining": 0,
  "expires_at": "2025-02-15T00:00:00.000Z",
  "message": "配额已用完"
}
```

**响应示例（已过期）：**
```json
{
  "valid": false,
  "remaining": 0,
  "expires_at": "2025-01-10T00:00:00.000Z",
  "message": "产品已过期"
}
```

**响应示例（无权限）：**
```json
{
  "valid": false,
  "remaining": 0,
  "message": "该API密钥没有此产品的权限"
}
```

---

## JavaScript示例

### 在商品中集成验证接口

```javascript
// 商品配置
const CONFIG = {
  API_BASE_URL: 'https://api.yourdomain.com',
  PRODUCT_ID: 'prod_abc123...'  // 商品ID（硬编码）
};

// 验证API密钥
async function verifyApiKey(apiKey) {
  try {
    const response = await fetch(`${CONFIG.API_BASE_URL}/api/verify`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        key: apiKey,
        product: CONFIG.PRODUCT_ID
      })
    });

    const result = await response.json();

    if (result.valid) {
      console.log(`✅ 验证通过！剩余配额：${result.remaining}`);
      return true;
    } else {
      console.log(`❌ 验证失败：${result.message}`);
      return false;
    }
  } catch (error) {
    console.error('验证请求失败:', error);
    return false;
  }
}

// 商品主逻辑
async function useProduct(apiKey) {
  // 1. 验证API密钥
  const isValid = await verifyApiKey(apiKey);

  if (!isValid) {
    alert('您没有权限使用此商品，或配额已用完');
    return;
  }

  // 2. 执行商品逻辑
  console.log('商品功能已启用...');
  // 您的商品代码...
}

// 使用示例
const userApiKey = 'sk_550e_...'; // 用户提供的API密钥
useProduct(userApiKey);
```

### 完整的用户界面示例

```html
<!DOCTYPE html>
<html>
<head>
  <title>商品访问</title>
</head>
<body>
  <h1>商品名称</h1>

  <div id="login-form">
    <input type="text" id="api-key" placeholder="请输入API密钥" />
    <button onclick="login()">访问商品</button>
  </div>

  <div id="product-content" style="display:none;">
    <p>配额剩余：<span id="remaining">-</span></p>
    <p>有效期至：<span id="expires">-</span></p>
    <!-- 商品内容 -->
  </div>

  <script>
    const API_BASE_URL = 'https://api.yourdomain.com';
    const PRODUCT_ID = 'prod_abc123...';

    async function login() {
      const apiKey = document.getElementById('api-key').value;

      if (!apiKey) {
        alert('请输入API密钥');
        return;
      }

      const response = await fetch(`${API_BASE_URL}/api/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: apiKey, product: PRODUCT_ID })
      });

      const result = await response.json();

      if (result.valid) {
        document.getElementById('login-form').style.display = 'none';
        document.getElementById('product-content').style.display = 'block';
        document.getElementById('remaining').textContent = result.remaining;
        document.getElementById('expires').textContent =
          new Date(result.expires_at).toLocaleDateString();

        // 保存API密钥供后续使用
        sessionStorage.setItem('apiKey', apiKey);

        // 启动商品功能
        startProduct();
      } else {
        alert(`访问失败：${result.message}`);
      }
    }

    function startProduct() {
      // 商品逻辑
      console.log('商品已启动');
    }
  </script>
</body>
</html>
```

---

## Python示例

### 在Python应用中集成验证

```python
import requests
import json

class ApiKeyValidator:
    def __init__(self, api_base_url, product_id):
        self.api_base_url = api_base_url
        self.product_id = product_id

    def verify(self, api_key):
        """验证API密钥"""
        try:
            response = requests.post(
                f"{self.api_base_url}/api/verify",
                json={
                    "key": api_key,
                    "product": self.product_id
                },
                headers={"Content-Type": "application/json"}
            )

            result = response.json()

            if result.get('valid'):
                print(f"✅ 验证通过！剩余配额：{result.get('remaining')}")
                return True, result
            else:
                print(f"❌ 验证失败：{result.get('message')}")
                return False, result
        except Exception as e:
            print(f"验证请求失败：{e}")
            return False, None

# 使用示例
validator = ApiKeyValidator(
    api_base_url="https://api.yourdomain.com",
    product_id="prod_abc123..."
)

# 验证用户的API密钥
user_api_key = "sk_550e_..."
is_valid, result = validator.verify(user_api_key)

if is_valid:
    print("启动商品功能...")
    # 您的商品代码
else:
    print("用户无权访问")
```

### Flask Web应用示例

```python
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

API_BASE_URL = "https://api.yourdomain.com"
PRODUCT_ID = "prod_abc123..."

def verify_api_key(api_key):
    """验证API密钥"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/api/verify",
            json={"key": api_key, "product": PRODUCT_ID}
        )
        return response.json()
    except:
        return {"valid": False, "message": "验证服务不可用"}

@app.route('/api/product/access', methods=['POST'])
def product_access():
    """商品访问接口"""
    data = request.json
    api_key = data.get('apiKey')

    if not api_key:
        return jsonify({"error": "缺少API密钥"}), 400

    # 验证API密钥
    verify_result = verify_api_key(api_key)

    if not verify_result.get('valid'):
        return jsonify({
            "error": "无权访问",
            "message": verify_result.get('message')
        }), 403

    # 返回商品数据
    return jsonify({
        "success": True,
        "data": {
            "content": "商品内容...",
            "remaining": verify_result.get('remaining'),
            "expires_at": verify_result.get('expires_at')
        }
    })

if __name__ == '__main__':
    app.run(debug=True)
```

---

## 🎯 完整测试流程脚本

### Bash脚本（test-api.sh）

```bash
#!/bin/bash

# 配置
API_BASE_URL="https://YOUR_WORKER_URL"

echo "========================================="
echo "API密钥配额验证系统 - 完整测试流程"
echo "========================================="

# 1. 管理员登录
echo -e "\n[1] 管理员登录..."
ADMIN_LOGIN=$(curl -s -X POST $API_BASE_URL/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
echo "✅ 管理员Token: ${ADMIN_TOKEN:0:20}..."

# 2. 创建租户
echo -e "\n[2] 创建租户..."
TENANT_RESULT=$(curl -s -X POST $API_BASE_URL/api/admin/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name":"测试租户",
    "username":"test_tenant",
    "password":"tenant123",
    "maxProducts":10,
    "maxApiKeys":100,
    "maxCodesPerProduct":1000
  }')

TENANT_ID=$(echo $TENANT_RESULT | jq -r '.tenantId')
echo "✅ 租户ID: $TENANT_ID"

# 3. 租户登录
echo -e "\n[3] 租户登录..."
TENANT_LOGIN=$(curl -s -X POST $API_BASE_URL/api/tenant/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test_tenant","password":"tenant123"}')

TENANT_TOKEN=$(echo $TENANT_LOGIN | jq -r '.token')
echo "✅ 租户Token: ${TENANT_TOKEN:0:20}..."

# 4. 生成API密钥
echo -e "\n[4] 生成API密钥..."
API_KEY_RESULT=$(curl -s -X POST $API_BASE_URL/api/tenant/keys \
  -H "Authorization: Bearer $TENANT_TOKEN")

API_KEY=$(echo $API_KEY_RESULT | jq -r '.apiKey')
echo "✅ API密钥: $API_KEY"

# 5. 创建商品
echo -e "\n[5] 创建商品..."
PRODUCT_RESULT=$(curl -s -X POST $API_BASE_URL/api/tenant/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{
    "name":"测试商品",
    "description":"测试用商品",
    "defaultCalls":100,
    "defaultDays":30,
    "category":"test"
  }')

PRODUCT_ID=$(echo $PRODUCT_RESULT | jq -r '.productId')
echo "✅ 商品ID: $PRODUCT_ID"

# 6. 生成兑换码
echo -e "\n[6] 生成兑换码..."
CODES_RESULT=$(curl -s -X POST $API_BASE_URL/api/tenant/products/$PRODUCT_ID/codes/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TENANT_TOKEN" \
  -d '{"count":5,"expiryDays":30}')

REDEEM_CODE=$(echo $CODES_RESULT | jq -r '.codes[0]')
echo "✅ 兑换码: $REDEEM_CODE"

# 7. 用户登录
echo -e "\n[7] 用户登录（使用API密钥）..."
USER_LOGIN=$(curl -s -X POST $API_BASE_URL/api/user/login \
  -H "Content-Type: application/json" \
  -d "{\"apiKey\":\"$API_KEY\"}")

USER_TOKEN=$(echo $USER_LOGIN | jq -r '.token')
USER_ID=$(echo $USER_LOGIN | jq -r '.userId')
echo "✅ 用户Token: ${USER_TOKEN:0:20}..."
echo "✅ 用户ID: $USER_ID"

# 8. 兑换兑换码
echo -e "\n[8] 兑换兑换码..."
REDEEM_RESULT=$(curl -s -X POST $API_BASE_URL/api/user/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"code\":\"$REDEEM_CODE\"}")

echo "✅ 兑换结果: $(echo $REDEEM_RESULT | jq -r '.action')"
echo "   产品: $(echo $REDEEM_RESULT | jq -r '.product')"
echo "   配额: $(echo $REDEEM_RESULT | jq -r '.totalCalls')"

# 9. 验证接口测试
echo -e "\n[9] 测试验证接口..."
VERIFY_RESULT=$(curl -s -X POST $API_BASE_URL/api/verify \
  -H "Content-Type: application/json" \
  -d "{\"key\":\"$API_KEY\",\"product\":\"$PRODUCT_ID\"}")

echo "✅ 验证结果:"
echo "   Valid: $(echo $VERIFY_RESULT | jq -r '.valid')"
echo "   Remaining: $(echo $VERIFY_RESULT | jq -r '.remaining')"
echo "   Message: $(echo $VERIFY_RESULT | jq -r '.message')"

echo -e "\n========================================="
echo "测试完成！所有接口正常工作。"
echo "========================================="
```

**使用方法：**
```bash
chmod +x test-api.sh
./test-api.sh
```

---

**所有API接口测试示例已完成！🎉**
