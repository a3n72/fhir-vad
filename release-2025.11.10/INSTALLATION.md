# 安裝指南

## 系統需求

- Docker 20.10+ 和 Docker Compose 2.0+
- 或 Java 17+ 和 Maven 3.6+
- PostgreSQL 15+（如果使用外部資料庫）
- Keycloak 22+（用於身份驗證）

## 安裝步驟

### 方法 1: 使用 Docker Compose（推薦）

1. **克隆或下載專案**

```bash
git clone <repository-url>
cd hapi-starter
```

2. **配置環境變數**

```bash
# 複製環境變數範例文件
cp .env.example .env

# 編輯 .env 文件
# 設定以下必要變數：
# - PG_HAPI_DB, PG_HAPI_USER, PG_HAPI_PASS
# - KEYCLOAK_URL, REALM, CLIENT_ID, CLIENT_SECRET
```

3. **配置授權規則**

編輯 `config/authz-rules.json`，設定角色和權限：

```json
{
  "roles": {
    "admin": {
      "read": ["*"],
      "write": ["*"],
      "delete": ["*"]
    }
  }
}
```

4. **啟動服務**

```bash
docker-compose up -d
```

5. **驗證安裝**

```bash
# 檢查服務狀態
docker-compose ps

# 查看日誌
docker-compose logs -f hapi

# 測試 API
curl http://localhost:8080/fhir/metadata
```

### 方法 2: 使用 Docker 映像

1. **從 Docker Hub 拉取映像**

```bash
docker pull <your-dockerhub-username>/hapi-fhir-jpaserver-starter:2025.11.10
```

2. **運行容器**

```bash
docker run -d \
  --name hapi-fhir \
  -p 8080:8080 \
  -v $(pwd)/config:/app/config \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/hapi \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=admin \
  -e SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=http://keycloak:8080/realms/fhir-realm/protocol/openid-connect/certs \
  -e SECURITY_JWT_ENABLED=true \
  <your-dockerhub-username>/hapi-fhir-jpaserver-starter:2025.11.10
```

### 方法 3: 本地構建

1. **安裝依賴**

```bash
mvn clean install
```

2. **運行應用**

```bash
mvn spring-boot:run
```

## Keycloak 配置

1. **創建 Realm**

- 登入 Keycloak 管理控制台
- 創建新 Realm：`fhir-realm`

2. **創建 Client**

- Client ID: `hapi-api`
- Client Protocol: `openid-connect`
- Access Type: `confidential`
- Valid Redirect URIs: `http://localhost:8080/*`
- Web Origins: `http://localhost:8080`

3. **配置 Audience Mapper**

- 創建 Protocol Mapper
- Mapper Type: `Audience`
- Included Client Audience: `hapi-api`

4. **創建用戶和角色**

- 創建用戶（如 `admin.user`, `nurse.alice` 等）
- 創建角色（如 `admin`, `nurse`, `clinician` 等）
- 將角色分配給用戶

## 驗證安裝

執行測試腳本驗證安裝：

```powershell
# Windows
.\test-all-users.ps1

# Linux/Mac
./test-all-users.sh
```

預期結果：所有測試通過（50/50）

## 故障排除

### 問題：服務無法啟動

1. 檢查日誌：`docker-compose logs hapi`
2. 確認資料庫連接正常
3. 確認 Keycloak 可訪問

### 問題：授權失敗（403）

1. 檢查 JWT Token 是否有效
2. 確認角色已正確分配
3. 檢查 `config/authz-rules.json` 配置
4. 查看日誌中的規則構建輸出

### 問題：規則未生效

1. 確認規則文件路徑正確
2. 檢查規則文件 JSON 格式
3. 查看日誌中的規則載入訊息

## 下一步

- 閱讀 [README.md](README.md) 了解功能
- 查看 [CONFIG_說明.md](../CONFIG_說明.md) 了解配置選項
- 參考 [Keycloak設定指南.md](../Keycloak設定指南.md) 配置 Keycloak

