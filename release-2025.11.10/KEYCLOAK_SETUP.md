# Keycloak 完整設置指南

## 📋 目錄

1. [快速設置檢查清單](#快速設置檢查清單)
2. [詳細設置步驟](#詳細設置步驟)
3. [測試用戶創建腳本](#測試用戶創建腳本)
4. [常見配置錯誤](#常見配置錯誤)

---

## 快速設置檢查清單

### ✅ 必須完成的項目

- [ ] Realm `fhir-realm` 已創建
- [ ] Client `hapi-api` 已創建
- [ ] Client Authentication 已啟用
- [ ] Client Secret 已獲取
- [ ] Audience Mapper 已配置（如果啟用 Audience 驗證）
- [ ] 所有 Realm Roles 已創建
- [ ] 所有測試用戶已創建
- [ ] 所有測試用戶的 First Name 和 Last Name 已設定
- [ ] 所有測試用戶的密碼已設定（非臨時）
- [ ] 所有測試用戶的 Email verified 已啟用
- [ ] 所有測試用戶的角色已分配

---

## 詳細設置步驟

### 步驟 1: 創建 Realm

1. 訪問 Keycloak：`http://localhost:8084`
2. 點擊「Administration Console」
3. 登入：`admin` / `admin`
4. 點擊「Create Realm」
5. 輸入名稱：`fhir-realm`
6. 點擊「Create」

### 步驟 2: 創建 Client

#### 2.1 基本資訊

1. 進入「Clients」→「Create client」
2. **Client type**: `OpenID Connect`
3. **Client ID**: `hapi-api`
4. 點擊「Next」

#### 2.2 Capability Config

**必須啟用**：
- ✅ **Client authentication**: `On`（重要！）
- ✅ **Authorization**: `On`
- ✅ **Standard flow**: `On`
- ✅ **Direct access grants**: `On`（用於測試腳本）

點擊「Next」

#### 2.3 Login Settings

- **Root URL**: `http://localhost:8080`
- **Valid redirect URIs**: `http://localhost:8080/*`
- **Web origins**: `http://localhost:8080`

點擊「Next」→「Save」

#### 2.4 獲取 Client Secret

1. 切換到「Credentials」標籤
2. 複製「Client secret」值
3. **保存此值**，稍後會用到

### 步驟 3: 配置 Audience Mapper

**如果 HAPI 配置了 `SECURITY_JWT_VALIDATE_AUDIENCE=true`，必須配置此 Mapper。**

1. 在 Client 設定頁面，切換到「Mappers」標籤
2. 點擊「Create mapper」
3. 選擇「By configuration」→「Audience」
4. 填寫：
   - **Name**: `hapi-audience-mapper`
   - **Included Client Audience**: `hapi-api`
5. 點擊「Save」

### 步驟 4: 創建 Realm Roles

需要創建以下角色：

#### 資源特定角色（10個）
- `read:Patient`, `write:Patient`
- `read:Observation`, `write:Observation`
- `read:Encounter`, `write:Encounter`
- `read:Condition`, `write:Condition`
- `read:MedicationRequest`, `write:MedicationRequest`

#### 功能角色（4個）
- `admin`
- `clinician`
- `nurse`
- `pharmacist`

**創建步驟**（對每個角色）：
1. 進入「Realm roles」
2. 點擊「Create role」
3. 輸入角色名稱
4. 點擊「Save」

### 步驟 5: 創建測試用戶

#### 5.1 用戶列表

| Username | Password | First Name | Last Name | 分配的角色 |
|----------|----------|------------|-----------|------------|
| `readonly.user` | `readonly123` | Readonly | User | `read:Patient` |
| `nurse.alice` | `nurse123` | Alice | Nurse | `nurse` |
| `clinician.bob` | `doctor123` | Bob | Clinician | `clinician` |
| `pharmacist.carol` | `pharma123` | Carol | Pharmacist | `pharmacist` |
| `admin.user` | `admin123` | Admin | User | `admin` |

#### 5.2 創建步驟（對每個用戶）

**A. 創建用戶基本資訊**

1. 進入「Users」→「Create new user」
2. 填寫：
   - **Username**: 見上表
   - **Email**: `<username>@example.com`
   - ✅ **Email verified**: `On`（重要！）
   - ✅ **Enabled**: `On`（重要！）
   - **First Name**: 見上表（**必須設定！**）
   - **Last Name**: 見上表（**必須設定！**）
3. 點擊「Create」

**B. 設定密碼**

1. 切換到「Credentials」標籤
2. 點擊「Set password」
3. 輸入密碼（見上表）
4. ✅ **取消勾選「Temporary」**（重要！）
5. 點擊「Save」

**C. 分配角色**

1. 切換到「Role Mappings」標籤
2. 點擊「Assign role」
3. 選擇對應的 Realm Role（見上表）
4. 點擊「Assign」

---

## 測試用戶創建腳本

可以使用以下 PowerShell 腳本快速創建所有測試用戶：

```powershell
# 創建測試用戶腳本
$keycloakUrl = "http://localhost:8084"
$realm = "fhir-realm"
$adminTokenUrl = "$keycloakUrl/realms/master/protocol/openid-connect/token"
$adminTokenBody = @{
    grant_type = "password"
    client_id = "admin-cli"
    username = "admin"
    password = "admin"
}

$adminTokenResponse = Invoke-RestMethod -Uri $adminTokenUrl -Method Post -Body $adminTokenBody
$adminToken = $adminTokenResponse.access_token
$headers = @{ Authorization = "Bearer $adminToken" }

$testUsers = @(
    @{ username = "readonly.user"; password = "readonly123"; firstName = "Readonly"; lastName = "User"; role = "read:Patient" },
    @{ username = "nurse.alice"; password = "nurse123"; firstName = "Alice"; lastName = "Nurse"; role = "nurse" },
    @{ username = "clinician.bob"; password = "doctor123"; firstName = "Bob"; lastName = "Clinician"; role = "clinician" },
    @{ username = "pharmacist.carol"; password = "pharma123"; firstName = "Carol"; lastName = "Pharmacist"; role = "pharmacist" },
    @{ username = "admin.user"; password = "admin123"; firstName = "Admin"; lastName = "User"; role = "admin" }
)

foreach ($user in $testUsers) {
    Write-Host "Creating user: $($user.username)" -ForegroundColor Cyan
    
    # 創建用戶
    $userBody = @{
        username = $user.username
        email = "$($user.username)@example.com"
        emailVerified = $true
        enabled = $true
        firstName = $user.firstName
        lastName = $user.lastName
    } | ConvertTo-Json
    
    try {
        $createUrl = "$keycloakUrl/admin/realms/$realm/users"
        $createResponse = Invoke-RestMethod -Uri $createUrl -Method Post -Headers $headers -Body $userBody -ContentType "application/json"
        
        # 獲取用戶 ID
        $users = Invoke-RestMethod -Uri "$keycloakUrl/admin/realms/$realm/users?username=$($user.username)" -Method Get -Headers $headers
        $userId = $users[0].id
        
        # 設定密碼
        $passwordBody = @{
            type = "password"
            value = $user.password
            temporary = $false
        } | ConvertTo-Json
        
        $passwordUrl = "$keycloakUrl/admin/realms/$realm/users/$userId/reset-password"
        Invoke-RestMethod -Uri $passwordUrl -Method Put -Headers $headers -Body $passwordBody -ContentType "application/json"
        
        # 分配角色
        $roles = Invoke-RestMethod -Uri "$keycloakUrl/admin/realms/$realm/roles" -Method Get -Headers $headers
        $role = $roles | Where-Object { $_.name -eq $user.role }
        
        if ($role) {
            $roleBody = @($role) | ConvertTo-Json
            $roleUrl = "$keycloakUrl/admin/realms/$realm/users/$userId/role-mappings/realm"
            Invoke-RestMethod -Uri $roleUrl -Method Post -Headers $headers -Body $roleBody -ContentType "application/json"
        }
        
        Write-Host "  ✓ User created: $($user.username)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to create user: $($user.username) - $_" -ForegroundColor Red
    }
}

Write-Host "`nAll users created!" -ForegroundColor Green
```

**使用方式**：
```powershell
# 保存為 create-test-users.ps1
.\create-test-users.ps1
```

---

## 常見配置錯誤

### 錯誤 1: "Account is not fully set up"

**原因**：
- 缺少 First Name 或 Last Name
- 密碼標記為臨時
- Email 未驗證

**解決**：
1. 設定 First Name 和 Last Name
2. 設定非臨時密碼
3. 啟用 Email verified

### 錯誤 2: Token 中沒有角色

**原因**：
- 角色未分配
- 角色在錯誤的位置（Client Roles vs Realm Roles）

**解決**：
1. 確認角色分配在 Realm Roles 中
2. 檢查 Role Mappings 標籤

### 錯誤 3: Audience 驗證失敗

**原因**：
- 未配置 Audience Mapper
- Audience 值不匹配

**解決**：
1. 配置 Audience Mapper
2. 確認 Audience 值為 `hapi-api`

### 錯誤 4: Client Secret 獲取失敗

**原因**：
- Client Authentication 未啟用
- Client ID 不正確

**解決**：
1. 確認 Client Authentication 為 `On`
2. 確認 Client ID 為 `hapi-api`

---

## 驗證配置

### 測試獲取 Token

```powershell
$body = @{
    grant_type = "password"
    client_id = "hapi-api"
    client_secret = "<your-client-secret>"
    username = "readonly.user"
    password = "readonly123"
}

$response = Invoke-RestMethod -Uri "http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token" -Method Post -Body $body
$token = $response.access_token
Write-Host "Token obtained successfully!"
```

### 解析 Token 驗證

訪問 https://jwt.io，貼上 Token，檢查：

- ✅ `realm_access.roles` 包含分配的角色
- ✅ `preferred_username` 正確
- ✅ `aud` 包含 `hapi-api`（如果啟用 Audience 驗證）
- ✅ `exp` 未過期

---

**最後更新**: 2025-11-10

