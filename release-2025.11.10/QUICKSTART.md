# 快速開始指南

## 5 分鐘快速部署

### 前置需求

- Docker 和 Docker Compose
- Keycloak 實例（或使用提供的 docker-compose.yml）

### 步驟 1: 配置環境變數

創建 `.env` 文件：

```bash
# 資料庫配置
PG_HAPI_DB=hapi
PG_HAPI_USER=admin
PG_HAPI_PASS=admin

# Keycloak 配置
KEYCLOAK_URL=http://localhost:8084
REALM=fhir-realm
CLIENT_ID=hapi-api
CLIENT_SECRET=<your-client-secret>
```

### 步驟 2: 配置授權規則

編輯 `config/authz-rules.json`：

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
  "users": {}
}
```

### 步驟 3: 啟動服務

```bash
docker-compose up -d
```

### 步驟 4: 驗證部署

```bash
# 檢查服務狀態
docker-compose ps

# 測試 API（無需認證的端點）
curl http://localhost:8080/actuator/health

# 測試 Metadata（需要 JWT Token）
curl -H "Authorization: Bearer <your-token>" http://localhost:8080/fhir/metadata
```

### 步驟 5: 執行測試

```powershell
# Windows
.\test-all-users.ps1
```

## 使用 Docker Hub 映像

如果您已經將映像推送到 Docker Hub：

```bash
# 拉取映像
docker pull <your-username>/hapi-fhir-jpaserver-starter:2025.11.10

# 使用 docker-compose.example.yml
# 修改其中的映像名稱
docker-compose -f docker-compose.example.yml up -d
```

## 常見問題

### Q: 如何獲取 JWT Token？

A: 使用 Keycloak 的 Token 端點：

```bash
curl -X POST http://localhost:8084/realms/fhir-realm/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=hapi-api" \
  -d "client_secret=<your-secret>"
```

### Q: 如何查看授權規則是否載入？

A: 查看日誌：

```bash
docker-compose logs hapi | grep "Rules loaded"
```

### Q: 如何修改授權規則？

A: 編輯 `config/authz-rules.json`，規則會自動在 3 秒內重新載入。

## 下一步

- 閱讀 [README.md](README.md) 了解完整功能
- 查看 [INSTALLATION.md](INSTALLATION.md) 了解詳細安裝步驟
- 參考 [DEPLOYMENT.md](DEPLOYMENT.md) 了解生產環境部署

