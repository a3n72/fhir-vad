# 故障排除指南

## 📋 目錄

1. [常見錯誤訊息](#常見錯誤訊息)
2. [診斷步驟](#診斷步驟)
3. [解決方案](#解決方案)
4. [我們遇到的問題與解決](#我們遇到的問題與解決)

---

## 常見錯誤訊息

### 錯誤 1: "Account is not fully set up"

**完整錯誤**：
```json
{
  "error": "invalid_grant",
  "error_description": "Account is not fully set up"
}
```

**發生時機**：獲取 Token 時

**原因**：
1. ❌ 用戶缺少 First Name 或 Last Name
2. ❌ 密碼標記為臨時（Temporary）
3. ❌ Email 未驗證
4. ❌ 帳號未啟用

**解決方案**：

#### 步驟 1: 檢查用戶設定

1. 登入 Keycloak 管理介面
2. 進入 Users → 選擇用戶
3. 檢查「Details」標籤：
   - ✅ **First Name**: 必須設定（例如：`Test`）
   - ✅ **Last Name**: 必須設定（例如：`User`）
   - ✅ **Email verified**: `On`
   - ✅ **Enabled**: `On`

#### 步驟 2: 設定密碼

1. 切換到「Credentials」標籤
2. 點擊「Set password」
3. 輸入密碼
4. ✅ **取消勾選「Temporary」**（重要！）
5. 點擊「Save」

#### 步驟 3: 清除 Required Actions

1. 在「Details」標籤中
2. 檢查「Required Actions」區塊
3. 如果有任何 Required Actions，移除它們

**驗證**：
```powershell
# 重新獲取 Token
$body = @{
    grant_type = "password"
    client_id = "hapi-api"
    client_secret = "<your-secret>"
    username = "readonly.user"
    password = "readonly123"
}
$response = Invoke-RestMethod -Uri "http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token" -Method Post -Body $body
# 應該成功，不再出現錯誤
```

---

### 錯誤 2: "Invalid client or Invalid client credentials"

**完整錯誤**：
```json
{
  "error": "unauthorized_client",
  "error_description": "Invalid client or Invalid client credentials"
}
```

**發生時機**：獲取 Token 時

**原因**：
1. ❌ Client ID 不正確
2. ❌ Client Secret 不正確
3. ❌ Client Authentication 未啟用

**解決方案**：

#### 步驟 1: 檢查 Client 設定

1. 進入 Clients → 選擇 `hapi-api`
2. 檢查「Settings」標籤：
   - ✅ **Client authentication**: `On`
3. 檢查「Credentials」標籤：
   - 複製正確的 Client Secret

#### 步驟 2: 驗證 Client ID

確認 Client ID 為 `hapi-api` 或 `hapi-fhir-client`

#### 步驟 3: 重新獲取 Client Secret

1. 進入 Client 設定 → Credentials 標籤
2. 點擊「Regenerate secret」（如果需要）
3. 複製新的 Client Secret
4. 更新測試腳本或配置

---

### 錯誤 3: "Access denied by rule: (unnamed rule)"

**完整錯誤**：
```
ca.uhn.fhir.rest.server.exceptions.ForbiddenOperationException: HAPI-0333: Access denied by rule: (unnamed rule)
```

**發生時機**：訪問 FHIR API 時

**原因**：
1. ❌ 授權規則未正確構建
2. ❌ 規則文件格式錯誤
3. ❌ 角色名稱不匹配
4. ❌ Token 中沒有角色

**解決方案**：

#### 步驟 1: 檢查規則文件

```powershell
# 檢查規則文件是否存在
docker-compose exec hapi ls -la /app/config/authz-rules.json

# 檢查規則文件內容
docker-compose exec hapi cat /app/config/authz-rules.json
```

確認：
- ✅ 文件存在
- ✅ JSON 格式正確
- ✅ 角色名稱與 Keycloak 一致

#### 步驟 2: 檢查規則載入

```powershell
docker-compose logs hapi | Select-String -Pattern "Rules loaded|Role.*granted"
```

應該看到：
```
[Authz] Rules loaded from ... (roles=X, users=Y)
[Authz] Role 'admin' granted: read=[*], write=[*], delete=[*]
```

#### 步驟 3: 檢查規則構建

```powershell
docker-compose logs hapi | Select-String -Pattern "Built rules count|DETAILED RULES OUTPUT"
```

應該看到：
```
[Authz] Built rules count = 5
[Authz] Rule 0: RuleImplOp - RuleImplOp[op=METADATA,...]
[Authz] Rule 1: RuleImplOp - RuleImplOp[op=READ,appliesTo=ALL_RESOURCES,...]
```

#### 步驟 4: 檢查 Token 中的角色

1. 獲取 Token
2. 在 https://jwt.io 解析 Token
3. 檢查 `realm_access.roles` 是否包含角色

---

### 錯誤 4: "JWT validation failed: Invalid audience"

**完整錯誤**：
```
JWT validation failed: Invalid audience
```

**發生時機**：HAPI 驗證 JWT Token 時

**原因**：
1. ❌ Token 中沒有 `aud` claim
2. ❌ `aud` 值與 HAPI 配置不一致
3. ❌ 未配置 Audience Mapper

**解決方案**：

#### 步驟 1: 配置 Audience Mapper

1. 進入 Client 設定 → Mappers 標籤
2. 點擊「Create mapper」
3. 選擇「Audience」
4. 填寫：
   - **Name**: `hapi-audience-mapper`
   - **Included Client Audience**: `hapi-api`
5. 點擊「Save」

#### 步驟 2: 檢查 HAPI 配置

```yaml
SECURITY_JWT_VALIDATE_AUDIENCE: "true"
SECURITY_JWT_ACCEPTED_AUDIENCES: "hapi-api,hapi-ui"
```

#### 步驟 3: 驗證 Token

在 https://jwt.io 解析 Token，確認 `aud` 包含 `hapi-api`

---

### 錯誤 5: "Rules file not found"

**完整錯誤**：
```
[Authz] ERROR: Rules file not found at: /app/config/authz-rules.json
```

**發生時機**：HAPI 啟動時

**原因**：
1. ❌ 規則文件不存在
2. ❌ 文件路徑不正確
3. ❌ 文件未掛載到容器

**解決方案**：

#### 步驟 1: 檢查文件是否存在

```powershell
# 檢查本地文件
ls config/authz-rules.json

# 檢查容器內文件
docker-compose exec hapi ls -la /app/config/authz-rules.json
```

#### 步驟 2: 檢查 docker-compose.yml

確認有 volume 掛載：

```yaml
volumes:
  - ./config:/app/config:ro
```

#### 步驟 3: 創建規則文件

如果文件不存在，創建 `config/authz-rules.json`：

```json
{
  "roles": {
    "admin": {
      "read": ["*"],
      "write": ["*"],
      "delete": ["*"]
    }
  },
  "users": {}
}
```

---

## 診斷步驟

### 快速診斷流程

```powershell
# 1. 檢查服務狀態
Write-Host "=== 檢查服務狀態 ===" -ForegroundColor Cyan
docker-compose ps

# 2. 檢查 Keycloak
Write-Host "`n=== 檢查 Keycloak ===" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/realms/master" -Method Get
    Write-Host "✓ Keycloak 運行正常" -ForegroundColor Green
} catch {
    Write-Host "✗ Keycloak 無法訪問: $_" -ForegroundColor Red
}

# 3. 檢查 HAPI
Write-Host "`n=== 檢查 HAPI ===" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get
    Write-Host "✓ HAPI 運行正常" -ForegroundColor Green
} catch {
    Write-Host "✗ HAPI 無法訪問: $_" -ForegroundColor Red
}

# 4. 檢查規則文件
Write-Host "`n=== 檢查規則文件 ===" -ForegroundColor Cyan
if (Test-Path "config/authz-rules.json") {
    Write-Host "✓ 規則文件存在" -ForegroundColor Green
    $content = Get-Content "config/authz-rules.json" -Raw | ConvertFrom-Json
    Write-Host "  角色數量: $($content.roles.PSObject.Properties.Count)" -ForegroundColor Cyan
} else {
    Write-Host "✗ 規則文件不存在" -ForegroundColor Red
}

# 5. 檢查規則載入
Write-Host "`n=== 檢查規則載入 ===" -ForegroundColor Cyan
$logs = docker-compose logs hapi --tail 100 2>&1
$rulesLoaded = $logs | Select-String -Pattern "Rules loaded"
if ($rulesLoaded) {
    Write-Host "✓ 規則已載入" -ForegroundColor Green
    Write-Host "  $rulesLoaded" -ForegroundColor Gray
} else {
    Write-Host "✗ 未找到規則載入日誌" -ForegroundColor Red
}

# 6. 測試獲取 Token
Write-Host "`n=== 測試獲取 Token ===" -ForegroundColor Cyan
try {
    $body = @{
        grant_type = "password"
        client_id = "hapi-api"
        client_secret = "<your-secret>"
        username = "readonly.user"
        password = "readonly123"
    }
    $response = Invoke-RestMethod -Uri "http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token" -Method Post -Body $body
    Write-Host "✓ Token 獲取成功" -ForegroundColor Green
} catch {
    Write-Host "✗ Token 獲取失敗: $_" -ForegroundColor Red
}
```

---

## 解決方案

### 問題分類

#### A. Keycloak 配置問題

**症狀**：
- 無法獲取 Token
- Token 中沒有角色
- Audience 驗證失敗

**解決**：
1. 參考 [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md)
2. 檢查 Client 設定
3. 檢查用戶設定
4. 檢查角色分配

#### B. HAPI 配置問題

**症狀**：
- JWT 驗證失敗
- 規則未載入
- 所有請求返回 403

**解決**：
1. 檢查環境變數
2. 檢查規則文件
3. 檢查日誌輸出

#### C. 授權規則問題

**症狀**：
- 規則構建但請求仍被拒絕
- 規則數量不正確

**解決**：
1. 檢查規則文件格式
2. 檢查角色名稱匹配
3. 查看規則構建日誌

---

## 我們遇到的問題與解決

### 問題 1: 規則構建只返回 2 條規則

**症狀**：
- 日誌顯示添加了多條規則
- 但 `build()` 只返回 2 條規則
- 所有請求返回 403

**原因**：
- HAPI FHIR 8.2.0 的 RuleBuilder API 行為差異
- `.andThen()` 未正確提交規則
- 規則被合併或覆蓋

**解決方案**：
- ✅ 改用「一規則一個 Builder」構建方式
- ✅ 每個規則使用獨立的 RuleBuilder
- ✅ 單獨 build() 後再合併

**參考代碼**：
```java
List<IAuthRule> out = new ArrayList<>();
out.addAll(new RuleBuilder().allow().metadata().build());
out.addAll(new RuleBuilder().allow().read().allResources().withAnyId().build());
// ...
```

### 問題 2: "Account is not fully set up"

**症狀**：
- 獲取 Token 時出現此錯誤
- 即使密碼已設定

**原因**：
- 缺少 First Name 或 Last Name
- 密碼標記為臨時

**解決方案**：
- ✅ 設定 First Name 和 Last Name
- ✅ 設定非臨時密碼
- ✅ 啟用 Email verified

### 問題 3: 規則熱重載不工作

**症狀**：
- 修改規則文件後規則未更新

**原因**：
- 文件未正確掛載
- 文件權限問題

**解決方案**：
- ✅ 確認 volume 掛載正確
- ✅ 檢查文件權限
- ✅ 等待 3 秒讓熱重載生效

### 問題 4: Token 中沒有角色

**症狀**：
- Token 獲取成功
- 但 `realm_access.roles` 為空
- 授權失敗

**原因**：
- 角色未分配
- 角色在錯誤的位置（Client Roles vs Realm Roles）

**解決方案**：
- ✅ 確認角色分配在 Realm Roles 中
- ✅ 檢查 Role Mappings
- ✅ 重新獲取 Token

### 問題 5: 日誌中出現 "allow $search operation"

**症狀**：
- 日誌中出現未預期的 "allow $search operation"

**原因**：
- 這是 `read().allResources()` 規則的 toString() 描述
- 不是額外的規則

**解決方案**：
- ✅ 這是正常現象，無需處理
- ✅ 搜尋操作被視為讀取操作的一部分

---

## 診斷工具

### 檢查腳本

可以使用以下腳本進行快速診斷：

```powershell
# 檢查 Keycloak 配置
.\check-keycloak-config.ps1

# 檢查用戶設定
.\check-keycloak-user.ps1 -Username readonly.user

# 檢查授權規則
.\check-authorization-settings.ps1

# 診斷授權問題
.\diagnose-authz.ps1
```

### 日誌分析

```powershell
# 查看規則構建日誌
docker-compose logs hapi | Select-String -Pattern "Rules|Role.*granted|Built"

# 查看錯誤日誌
docker-compose logs hapi | Select-String -Pattern "ERROR|Exception|403"

# 查看完整日誌
docker-compose logs hapi --tail 500
```

---

## 聯繫支援

如果以上方法都無法解決問題：

1. **收集資訊**：
   - 錯誤訊息
   - 日誌輸出
   - 配置文件（移除敏感資訊）

2. **執行診斷**：
   ```powershell
   # 收集所有日誌
   docker-compose logs hapi > hapi-logs.txt
   docker-compose logs keycloak > keycloak-logs.txt
   ```

3. **描述問題**：
   - 執行步驟
   - 預期結果
   - 實際結果
   - 錯誤訊息

---

**最後更新**: 2025-11-10

