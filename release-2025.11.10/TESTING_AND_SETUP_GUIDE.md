# 測試與設置完整指南

## 📋 目錄

1. [前置需求](#前置需求)
2. [Keycloak 完整設置](#keycloak-完整設置)
3. [測試腳本設置與執行](#測試腳本設置與執行)
4. [常見問題與排錯](#常見問題與排錯)
5. [QA 問題與解決方案](#qa-問題與解決方案)

---

## 前置需求

### 系統需求

- Docker 和 Docker Compose
- PowerShell 5.1+（Windows）或 Bash（Linux/Mac）
- Keycloak 22+ 實例
- PostgreSQL 15+（如果使用外部資料庫）

### 服務狀態檢查

```powershell
# 檢查 Docker 服務
docker ps

# 檢查 Keycloak 是否運行
curl http://localhost:8084/realms/master

# 檢查 HAPI 是否運行
curl http://localhost:8080/actuator/health
```

---

## Keycloak 完整設置

### 步驟 1: 登入 Keycloak 管理介面

1. 訪問：`http://localhost:8084`
2. 點擊右上角「Administration Console」
3. 登入：
   - **Username**: `admin`
   - **Password**: `admin`

### 步驟 2: 創建 Realm

1. 在左側選單點擊「Create Realm」
2. 輸入 Realm 名稱：`fhir-realm`
3. 點擊「Create」

### 步驟 3: 創建 Client（用於 HAPI FHIR API）

#### 3.1 基本設置

1. 在 `fhir-realm` 中，點擊左側選單「Clients」
2. 點擊「Create client」
3. 填寫：
   - **Client type**: `OpenID Connect`
   - **Client ID**: `hapi-api`
   - 點擊「Next」

#### 3.2 Capability Config

- ✅ **Client authentication**: `On`（重要！）
- ✅ **Authorization**: `On`
- ✅ **Standard flow**: `On`
- ✅ **Direct access grants**: `On`（用於測試）
- 點擊「Next」

#### 3.3 Login Settings

- **Root URL**: `http://localhost:8080`
- **Valid redirect URIs**: `http://localhost:8080/*`
- **Web origins**: `http://localhost:8080`
- 點擊「Next」

#### 3.4 保存

點擊「Save」

#### 3.5 獲取 Client Secret

1. 切換到「Credentials」標籤
2. 複製「Client secret」值（稍後會用到）

### 步驟 4: 配置 Audience Mapper（如果啟用 Audience 驗證）

1. 在 Client 設定頁面，切換到「Mappers」標籤
2. 點擊「Create mapper」
3. 選擇「By configuration」，選擇「Audience」
4. 填寫：
   - **Name**: `hapi-audience-mapper`
   - **Included Client Audience**: `hapi-api`
   - 點擊「Save」

**重要**：如果 HAPI 配置了 `SECURITY_JWT_VALIDATE_AUDIENCE=true`，必須配置此 Mapper。

### 步驟 5: 創建 Realm Roles

需要創建以下角色（在「Realm roles」中）：

#### 資源特定角色
- `read:Patient`, `write:Patient`
- `read:Observation`, `write:Observation`
- `read:Encounter`, `write:Encounter`
- `read:Condition`, `write:Condition`
- `read:MedicationRequest`, `write:MedicationRequest`

#### 功能角色
- `admin` - 完全權限
- `clinician` - 臨床醫生
- `nurse` - 護士
- `pharmacist` - 藥劑師

**創建步驟**：
1. 進入「Realm roles」
2. 點擊「Create role」
3. 輸入角色名稱
4. 點擊「Save」
5. 重複以上步驟創建所有角色

### 步驟 6: 創建測試用戶

需要創建以下測試用戶：

#### 6.1 創建用戶基本資訊

對每個用戶執行以下步驟：

1. 點擊「Users」→「Create new user」
2. 填寫：
   - **Username**: 見下方列表
   - **Email**: `<username>@example.com`
   - ✅ **Email verified**: `On`
   - ✅ **Enabled**: `On`
   - **First Name**: 見下方列表（**必須設定！**）
   - **Last Name**: 見下方列表（**必須設定！**）
3. 點擊「Create」

#### 6.2 設定密碼

1. 切換到「Credentials」標籤
2. 點擊「Set password」
3. 輸入密碼（見下方列表）
4. ✅ **取消勾選「Temporary」**（重要！）
5. 點擊「Save」

#### 6.3 分配角色

1. 切換到「Role Mappings」標籤
2. 點擊「Assign role」
3. 選擇對應的 Realm Role（見下方列表）
4. 點擊「Assign」

#### 測試用戶列表

| Username | Password | First Name | Last Name | 分配的角色 |
|----------|----------|------------|-----------|------------|
| `readonly.user` | `readonly123` | Readonly | User | `read:Patient` |
| `nurse.alice` | `nurse123` | Alice | Nurse | `nurse` |
| `clinician.bob` | `doctor123` | Bob | Clinician | `clinician` |
| `pharmacist.carol` | `pharma123` | Carol | Pharmacist | `pharmacist` |
| `admin.user` | `admin123` | Admin | User | `admin` |

**重要提醒**：
- ✅ **First Name 和 Last Name 必須設定**，否則會出現 "Account is not fully set up" 錯誤
- ✅ **密碼必須取消「Temporary」選項**，否則會導致驗證失敗
- ✅ **Email verified 必須啟用**

### 步驟 7: 驗證配置

#### 7.1 測試獲取 Token

```powershell
# 使用 readonly.user 測試
$body = @{
    grant_type = "password"
    client_id = "hapi-api"
    client_secret = "<your-client-secret>"
    username = "readonly.user"
    password = "readonly123"
}

$response = Invoke-RestMethod -Uri "http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token" -Method Post -Body $body
$token = $response.access_token
Write-Host "Token obtained: $($token.Substring(0, 50))..."
```

#### 7.2 解析 Token 驗證角色

訪問 https://jwt.io，貼上 Token，檢查：

- ✅ `realm_access.roles` 包含分配的角色
- ✅ `preferred_username` 正確
- ✅ `aud` 包含 `hapi-api`（如果啟用 Audience 驗證）

---

## 測試腳本設置與執行

### 測試腳本說明

`test-all-users.ps1` 會測試所有用戶的授權功能，包括：
- 讀取權限驗證
- 寫入權限驗證
- 權限拒絕驗證

### 設置步驟

#### 步驟 1: 檢查環境變數

測試腳本使用以下預設值，如需修改請編輯腳本：

```powershell
$keycloakUrl = "http://localhost:8084"
$realm = "fhir-realm"
$hapiUrl = "http://localhost:8080"
```

#### 步驟 2: 確認服務運行

```powershell
# 檢查 Keycloak
curl http://localhost:8084/realms/master

# 檢查 HAPI
curl http://localhost:8080/actuator/health
```

#### 步驟 3: 確認 Keycloak 配置

- ✅ Client `hapi-api` 已創建
- ✅ Client Secret 已獲取
- ✅ 所有測試用戶已創建
- ✅ 所有角色已分配

#### 步驟 4: 執行測試

```powershell
# 從 release 目錄執行
cd release-2025.11.10
.\test-all-users.ps1

# 或從專案根目錄執行
.\test-all-users.ps1
```

### 測試結果解讀

#### 成功範例

```
Overall Results:
  - Passed: 50
  - Failed: 0
  - Validation Errors (excluded): 11
```

- **Passed**: 授權測試通過的數量
- **Failed**: 授權測試失敗的數量（應該為 0）
- **Validation Errors**: 資源驗證錯誤（非授權問題，已排除）

#### 失敗範例

如果看到失敗：

```
User: nurse.alice (Role: nurse)
  ❌ Some tests failed:
    - READ Patient: Expected ALLOW, Got DENY
```

**可能原因**：
1. 角色未正確分配
2. 授權規則配置錯誤
3. Token 中沒有角色

---

## 常見問題與排錯

### 問題 1: "Account is not fully set up"

**錯誤訊息**：
```
"error":"invalid_grant","error_description":"Account is not fully set up"
```

**原因**：
- 用戶缺少 First Name 或 Last Name
- 密碼標記為臨時（Temporary）
- Email 未驗證
- 帳號未啟用

**解決方案**：

1. **設定 First Name 和 Last Name**（最重要！）
   - 進入用戶設定 → Details 標籤
   - 填寫 First Name 和 Last Name
   - 點擊「Save」

2. **設定非臨時密碼**
   - 進入用戶設定 → Credentials 標籤
   - 點擊「Set password」
   - 輸入密碼
   - ✅ **取消勾選「Temporary」**
   - 點擊「Save」

3. **啟用帳號和驗證 Email**
   - 進入用戶設定 → Details 標籤
   - ✅ 啟用「Enabled」
   - ✅ 啟用「Email verified」
   - 點擊「Save」

### 問題 2: Token 中沒有角色

**症狀**：
- 測試腳本顯示角色為空
- 授權失敗（403）

**檢查步驟**：

1. **檢查用戶角色分配**
   ```powershell
   # 使用檢查腳本
   .\check-keycloak-user.ps1 -Username readonly.user
   ```

2. **檢查 Token 內容**
   - 在 jwt.io 解析 Token
   - 檢查 `realm_access.roles` 是否包含角色

3. **檢查 Client Mappers**
   - 進入 Client 設定 → Mappers 標籤
   - 確認有 Role Mapper（通常是預設的）

**解決方案**：

1. **重新分配角色**
   - 進入用戶設定 → Role Mappings 標籤
   - 確認角色在「Assigned Roles」中
   - 如果不在，點擊「Assign role」添加

2. **重新獲取 Token**
   - 刪除舊 Token
   - 重新執行測試腳本

### 問題 3: Audience 驗證失敗

**錯誤訊息**：
```
JWT validation failed: Invalid audience
```

**原因**：
- Token 中沒有 `aud` claim
- `aud` 值與 HAPI 配置不一致

**解決方案**：

1. **配置 Audience Mapper**
   - 進入 Client 設定 → Mappers 標籤
   - 創建 Audience Mapper
   - 設置 Included Client Audience 為 `hapi-api`

2. **檢查 HAPI 配置**
   ```yaml
   SECURITY_JWT_VALIDATE_AUDIENCE: "true"
   SECURITY_JWT_ACCEPTED_AUDIENCES: "hapi-api,hapi-ui"
   ```

3. **驗證 Token**
   - 在 jwt.io 解析 Token
   - 確認 `aud` 包含 `hapi-api`

### 問題 4: 授權規則未生效

**症狀**：
- 所有請求都返回 403
- 日誌顯示規則構建但請求仍被拒絕

**檢查步驟**：

1. **檢查規則文件**
   ```powershell
   # 檢查規則文件是否存在
   docker-compose exec hapi ls -la /app/config/authz-rules.json
   
   # 檢查規則文件內容
   docker-compose exec hapi cat /app/config/authz-rules.json
   ```

2. **檢查日誌**
   ```powershell
   docker-compose logs hapi | Select-String -Pattern "Rules loaded|Role.*granted|Built rules count"
   ```

3. **檢查規則構建**
   ```powershell
   docker-compose logs hapi | Select-String -Pattern "DETAILED RULES OUTPUT|Rule \d+:"
   ```

**解決方案**：

1. **確認規則文件格式正確**
   - JSON 格式正確
   - 角色名稱與 Keycloak 一致

2. **確認角色匹配**
   - 檢查 Token 中的角色
   - 確認規則文件中有對應的角色配置

3. **重啟服務**
   ```powershell
   docker-compose restart hapi
   ```

### 問題 5: 規則熱重載不工作

**症狀**：
- 修改規則文件後規則未更新

**檢查步驟**：

1. **檢查文件路徑**
   ```powershell
   docker-compose exec hapi ls -la /app/config/authz-rules.json
   ```

2. **檢查文件權限**
   ```powershell
   docker-compose exec hapi stat /app/config/authz-rules.json
   ```

3. **檢查日誌**
   ```powershell
   docker-compose logs hapi | Select-String -Pattern "Rules reloaded"
   ```

**解決方案**：

1. **確認文件掛載正確**
   ```yaml
   volumes:
     - ./config:/app/config:ro
   ```

2. **觸發手動重載**
   - 修改規則文件（例如添加註釋）
   - 保存文件
   - 等待 3 秒後查看日誌

---

## QA 問題與解決方案

### Q1: 為什麼需要設定 First Name 和 Last Name？

**A**: Keycloak 的 "Condition - user configured" 執行器會檢查用戶是否完全設定好，包括基本資訊（姓名）。這是 Keycloak 的安全機制，確保用戶帳號的完整性。

**解決方案**：在創建用戶時必須設定 First Name 和 Last Name。

### Q2: 為什麼密碼不能是臨時的？

**A**: 臨時密碼會觸發 Keycloak 的 Required Actions，導致 "Account is not fully set up" 錯誤。

**解決方案**：設定密碼時取消勾選「Temporary」選項。

### Q3: Token 中沒有角色怎麼辦？

**A**: 可能原因：
1. 用戶未分配角色
2. 角色在錯誤的位置（Client Roles vs Realm Roles）
3. Client Mapper 配置錯誤

**解決方案**：
1. 確認角色分配在 Realm Roles 中
2. 檢查 Token 中的 `realm_access.roles`
3. 確認 Client 有正確的 Role Mapper

### Q4: 為什麼所有請求都返回 403？

**A**: 可能原因：
1. 授權規則未正確構建
2. 規則文件格式錯誤
3. 角色名稱不匹配

**解決方案**：
1. 檢查日誌中的規則構建輸出
2. 確認規則文件 JSON 格式正確
3. 確認角色名稱與 Keycloak 一致

### Q5: 如何確認授權規則已載入？

**A**: 查看日誌：

```powershell
docker-compose logs hapi | Select-String -Pattern "Rules loaded|Role.*granted|Built rules count"
```

應該看到：
- `Rules loaded from ... (roles=X, users=Y)`
- `Role 'admin' granted: read=[*], write=[*], delete=[*]`
- `Built rules count = 5`

### Q6: 規則修改後多久生效？

**A**: 規則熱重載每 3 秒檢查一次文件變更。修改規則文件後，等待 3-5 秒即可生效。

**驗證**：
```powershell
# 修改規則文件
# 等待 3 秒後查看日誌
docker-compose logs hapi --tail 50 | Select-String -Pattern "Rules reloaded"
```

### Q7: 如何測試單個用戶的權限？

**A**: 修改測試腳本，只測試特定用戶：

```powershell
# 在 test-all-users.ps1 中，只保留要測試的用戶
$testUsers = @(
    @{
        username = "nurse.alice"
        # ... 其他配置
    }
)
```

### Q8: 如何查看實際構建的規則？

**A**: 查看日誌中的詳細規則輸出：

```powershell
docker-compose logs hapi | Select-String -Pattern "DETAILED RULES OUTPUT|Rule \d+:"
```

應該看到類似：
```
[Authz] Rule 0: RuleImplOp - RuleImplOp[op=METADATA,...]
[Authz] Rule 1: RuleImplOp - RuleImplOp[op=READ,appliesTo=ALL_RESOURCES,...]
[Authz] Rule 2: RuleImplOp - RuleImplOp[op=WRITE,appliesTo=ALL_RESOURCES,...]
```

### Q9: 為什麼測試腳本無法獲取 Client Secret？

**A**: 可能原因：
1. Keycloak 未運行
2. Client ID 不正確
3. Admin 帳號密碼錯誤

**解決方案**：
1. 確認 Keycloak 運行：`curl http://localhost:8084/realms/master`
2. 確認 Client ID 為 `hapi-api` 或 `hapi-fhir-client`
3. 確認 Admin 帳號為 `admin/admin`

### Q10: 如何重置所有測試用戶？

**A**: 使用 Keycloak 管理介面：

1. 進入 Users
2. 搜尋並選擇用戶
3. 點擊「Delete」刪除
4. 重新創建用戶（參考步驟 6）

或使用腳本（如果有的話）：
```powershell
.\create-test-users.ps1
```

---

## 快速診斷清單

### 檢查清單

執行測試前，確認以下項目：

- [ ] Keycloak 運行正常
- [ ] HAPI 運行正常
- [ ] Realm `fhir-realm` 已創建
- [ ] Client `hapi-api` 已創建並配置
- [ ] Client Secret 已獲取
- [ ] 所有 Realm Roles 已創建
- [ ] 所有測試用戶已創建
- [ ] 所有測試用戶的 First Name 和 Last Name 已設定
- [ ] 所有測試用戶的密碼已設定（非臨時）
- [ ] 所有測試用戶的 Email verified 已啟用
- [ ] 所有測試用戶的角色已分配
- [ ] 規則文件 `config/authz-rules.json` 存在且格式正確
- [ ] 規則文件中的角色名稱與 Keycloak 一致

### 診斷命令

```powershell
# 1. 檢查服務狀態
docker-compose ps

# 2. 檢查 Keycloak
curl http://localhost:8084/realms/master

# 3. 檢查 HAPI
curl http://localhost:8080/actuator/health

# 4. 檢查規則文件
docker-compose exec hapi cat /app/config/authz-rules.json

# 5. 檢查規則載入
docker-compose logs hapi | Select-String -Pattern "Rules loaded"

# 6. 檢查規則構建
docker-compose logs hapi | Select-String -Pattern "Built rules count"

# 7. 測試獲取 Token
$body = @{
    grant_type = "password"
    client_id = "hapi-api"
    client_secret = "<your-secret>"
    username = "readonly.user"
    password = "readonly123"
}
$response = Invoke-RestMethod -Uri "http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token" -Method Post -Body $body
Write-Host "Token: $($response.access_token.Substring(0, 50))..."
```

---

## 聯繫支援

如果以上方法都無法解決問題，請：

1. 收集日誌：
   ```powershell
   docker-compose logs hapi > hapi-logs.txt
   docker-compose logs keycloak > keycloak-logs.txt
   ```

2. 收集配置：
   - `config/authz-rules.json`
   - `docker-compose.yml`
   - `.env`（移除敏感資訊）

3. 描述問題：
   - 錯誤訊息
   - 執行步驟
   - 預期結果 vs 實際結果

---

**最後更新**: 2025-11-10  
**版本**: 2025.11.10

