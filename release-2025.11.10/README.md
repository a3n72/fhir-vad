# HAPI FHIR JPA Server Starter - Release 2025.11.10

## 版本資訊

- **版本號**: 2025.11.10
- **HAPI FHIR 版本**: 8.2.0
- **Java 版本**: 17
- **構建日期**: 2025-11-10

## 主要功能

本版本包含以下主要功能：

1. **JWT 身份驗證**
   - 支援 Keycloak OAuth2/OIDC
   - JWT Token 驗證
   - 自動 Audience 驗證

2. **基於角色的授權系統**
   - 支援基於 JWT Token 中角色的動態授權
   - 外部 JSON 規則文件配置
   - 支援讀取、寫入、刪除權限控制
   - 規則熱重載（每 3 秒自動檢測變更）

3. **授權規則配置**
   - 角色基礎權限配置
   - 用戶級別權限覆寫
   - 支援通配符（*）和特定資源類型

## 快速開始

### 使用 Docker Compose（推薦）

```bash
# 1. 複製環境變數文件
cp .env.example .env

# 2. 編輯 .env 文件，設定必要的環境變數
# 特別是 Keycloak 相關配置

# 3. 啟動服務
docker-compose up -d

# 4. 檢查服務狀態
docker-compose ps

# 5. 查看日誌
docker-compose logs -f hapi
```

### 使用 Docker 映像

```bash
# 從 Docker Hub 拉取映像
docker pull <your-dockerhub-username>/hapi-fhir-jpaserver-starter:2025.11.10

# 運行容器
docker run -d \
  --name hapi-fhir \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/hapi \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=admin \
  -e SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=http://keycloak:8080/realms/fhir-realm/protocol/openid-connect/certs \
  -e SECURITY_JWT_ENABLED=true \
  <your-dockerhub-username>/hapi-fhir-jpaserver-starter:2025.11.10
```

## 配置說明

### 環境變數

主要環境變數說明：

- `SPRING_DATASOURCE_URL`: PostgreSQL 資料庫連接 URL
- `SPRING_DATASOURCE_USERNAME`: 資料庫用戶名
- `SPRING_DATASOURCE_PASSWORD`: 資料庫密碼
- `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI`: Keycloak JWKS 端點
- `SECURITY_JWT_ENABLED`: 是否啟用 JWT 驗證（true/false）
- `AUTHZ_RULES_PATH`: 授權規則文件路徑（預設：/app/config/authz-rules.json）

### 授權規則配置

授權規則文件位於 `config/authz-rules.json`，格式如下：

```json
{
  "roles": {
    "admin": {
      "read": ["*"],
      "write": ["*"],
      "delete": ["*"]
    },
    "nurse": {
      "read": ["Patient", "Observation", "Encounter"],
      "write": ["Observation"],
      "delete": []
    }
  },
  "users": {
    "specific.user": {
      "read": ["Patient"],
      "write": [],
      "delete": [],
      "add_roles": ["nurse"]
    }
  }
}
```

## 測試

### 執行完整測試

```powershell
# Windows PowerShell
.\test-all-users.ps1
```

測試腳本會驗證：
- 不同角色的讀取權限
- 不同角色的寫入權限
- 權限拒絕情況

## API 端點

- **FHIR Base URL**: `http://localhost:8080/fhir/`
- **Metadata**: `http://localhost:8080/fhir/metadata`
- **Health Check**: `http://localhost:8080/actuator/health`

## 已知問題

1. `$validate` 操作規則暫時未實現（HAPI FHIR 8.2.0 API 限制）
2. 攔截器檢測功能暫時註釋（API 限制）

## 更新日誌

### 2025.11.10

- ✅ 修復授權規則構建問題
- ✅ 改用「一規則一個 Builder」構建方式
- ✅ 所有測試通過（50/50）
- ✅ 支援動態規則熱重載
- ✅ 完整的角色基礎授權系統

## 技術支援

如有問題，請參考：
- [HAPI FHIR 官方文檔](https://hapifhir.io/hapi-fhir/docs/introduction/introduction.html)
- [Keycloak 文檔](https://www.keycloak.org/documentation)

## 授權

本專案基於 Apache License 2.0 授權。

