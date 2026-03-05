# 部署指南

## Docker Hub 推送

### 使用 PowerShell 腳本（Windows）

```powershell
.\build-and-push.ps1 -DockerHubUsername <your-username> -DockerHubPassword <your-password>
```

### 使用 Bash 腳本（Linux/Mac）

```bash
chmod +x build-and-push.sh
./build-and-push.sh <your-username> <your-password>
```

### 手動構建和推送

```bash
# 1. 登入 Docker Hub
docker login

# 2. 構建映像
docker build --target spring-boot -t <your-username>/hapi-fhir-jpaserver-starter:2025.11.10 -t <your-username>/hapi-fhir-jpaserver-starter:latest .

# 3. 推送映像
docker push <your-username>/hapi-fhir-jpaserver-starter:2025.11.10
docker push <your-username>/hapi-fhir-jpaserver-starter:latest
```

## 生產環境部署

### 使用 Docker Compose

1. **準備環境變數文件**

```bash
cp .env.example .env
# 編輯 .env，設定生產環境變數
```

2. **配置授權規則**

編輯 `config/authz-rules.json`，設定生產環境的角色和權限。

3. **啟動服務**

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 使用 Kubernetes

參考 `charts/hapi-fhir-jpaserver/` 目錄中的 Helm Chart。

### 環境變數配置

生產環境建議設定：

```bash
# 資料庫
SPRING_DATASOURCE_URL=jdbc:postgresql://prod-db:5432/hapi
SPRING_DATASOURCE_USERNAME=<secure-username>
SPRING_DATASOURCE_PASSWORD=<secure-password>

# Keycloak
SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=https://keycloak.example.com/realms/fhir-realm/protocol/openid-connect/certs

# JVM 設定
JAVA_TOOL_OPTIONS="-Xmx2g -Xms1g -XX:+UseG1GC"

# 日誌級別
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_CA_UHN_FHIR=DEBUG
```

## 監控和維護

### 健康檢查

```bash
curl http://localhost:8080/actuator/health
```

### 日誌查看

```bash
# Docker Compose
docker-compose logs -f hapi

# Docker
docker logs -f hapi-fhir
```

### 備份資料庫

```bash
# 使用提供的備份腳本
.\scripts\dump_data.ps1
```

### 恢復資料庫

```bash
# 使用提供的恢復腳本
.\scripts\restore_data.ps1
```

## 安全建議

1. **使用強密碼**
   - 資料庫密碼
   - Keycloak Client Secret

2. **啟用 HTTPS**
   - 使用反向代理（如 Nginx）
   - 配置 SSL/TLS 證書

3. **限制網路訪問**
   - 使用防火牆規則
   - 限制資料庫僅內部訪問

4. **定期更新**
   - 定期更新 Docker 映像
   - 關注安全公告

5. **監控和審計**
   - 啟用日誌記錄
   - 監控異常訪問

