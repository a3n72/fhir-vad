# Docker 映像構建說明

## 概述

本指南說明如何構建 HAPI FHIR JPA Server Starter 的 Docker 映像。

**注意**：本指南僅包含本地構建，不包含推送到 Docker Hub 的步驟。

## 前置需求

- Docker 20.10+ 已安裝並運行
- 足夠的磁碟空間（約 2GB）
- 穩定的網路連接（用於下載依賴）

## 構建方法

### 方法 1: 使用自動化腳本（推薦）

#### Windows PowerShell

```powershell
# 切換到 release 目錄
cd release-2025.11.10

# 執行構建腳本（使用預設值）
.\build-and-push.ps1

# 或指定版本和映像名稱
.\build-and-push.ps1 -Version 2025.11.10 -ImageName hapi-fhir-jpaserver-starter -Tag latest
```

#### Linux/Mac

```bash
# 切換到 release 目錄
cd release-2025.11.10

# 設定執行權限
chmod +x build-and-push.sh

# 執行構建腳本（使用預設值）
./build-and-push.sh

# 或指定版本和映像名稱
./build-and-push.sh 2025.11.10 hapi-fhir-jpaserver-starter latest
```

### 方法 2: 手動構建

#### 步驟 1: 切換到專案根目錄

```bash
# 從 release-2025.11.10 目錄回到專案根目錄
cd ..
```

#### 步驟 2: 構建映像

```bash
# 構建映像（同時創建版本標籤和 latest 標籤）
docker build --target spring-boot \
  -t hapi-fhir-jpaserver-starter:2025.11.10 \
  -t hapi-fhir-jpaserver-starter:latest \
  .
```

**參數說明**：
- `--target spring-boot`: 使用 Spring Boot 內嵌伺服器版本（推薦）
- `-t <tag>`: 指定映像標籤
- `.`: 構建上下文（當前目錄）

#### 步驟 3: 驗證構建

```bash
# 查看構建的映像
docker images | grep hapi-fhir-jpaserver-starter

# 應該看到類似輸出：
# hapi-fhir-jpaserver-starter   2025.11.10    <image-id>    <time>    1.05GB
# hapi-fhir-jpaserver-starter   latest        <image-id>    <time>    1.05GB
```

## 構建時間

構建時間取決於：
- 網路速度（下載依賴）
- CPU 性能
- 磁碟 I/O 速度

**預估時間**：
- 首次構建：10-20 分鐘（需要下載所有依賴）
- 後續構建：5-10 分鐘（使用緩存）

## 構建選項

### 使用不同的標籤

```bash
# 只構建版本標籤
docker build --target spring-boot -t hapi-fhir-jpaserver-starter:2025.11.10 .

# 構建多個標籤
docker build --target spring-boot \
  -t hapi-fhir-jpaserver-starter:2025.11.10 \
  -t hapi-fhir-jpaserver-starter:v1 \
  -t my-custom-tag:latest \
  .
```

### 不使用緩存構建

```bash
# 強制重新構建所有層
docker build --no-cache --target spring-boot \
  -t hapi-fhir-jpaserver-starter:2025.11.10 \
  .
```

### 查看構建過程

```bash
# 顯示詳細構建輸出
docker build --target spring-boot \
  --progress=plain \
  -t hapi-fhir-jpaserver-starter:2025.11.10 \
  .
```

## 使用構建的映像

### 運行容器

```bash
# 基本運行
docker run -d \
  --name hapi-fhir \
  -p 8080:8080 \
  hapi-fhir-jpaserver-starter:2025.11.10

# 帶環境變數運行
docker run -d \
  --name hapi-fhir \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/hapi \
  -e SPRING_DATASOURCE_USERNAME=admin \
  -e SPRING_DATASOURCE_PASSWORD=admin \
  hapi-fhir-jpaserver-starter:2025.11.10

# 掛載配置文件
docker run -d \
  --name hapi-fhir \
  -p 8080:8080 \
  -v $(pwd)/config:/app/config:ro \
  hapi-fhir-jpaserver-starter:2025.11.10
```

### 使用 Docker Compose

編輯 `docker-compose.yml`：

```yaml
services:
  hapi:
    image: hapi-fhir-jpaserver-starter:2025.11.10
    # 或使用 latest
    # image: hapi-fhir-jpaserver-starter:latest
    ports:
      - "8080:8080"
    volumes:
      - ./config:/app/config:ro
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://pg-hapi:5432/hapi
      SPRING_DATASOURCE_USERNAME: admin
      SPRING_DATASOURCE_PASSWORD: admin
```

然後運行：

```bash
docker-compose up -d
```

## 故障排除

### 問題 1: 構建失敗 - "Cannot connect to Docker daemon"

**原因**：Docker 未運行

**解決方案**：
```bash
# 啟動 Docker
# Windows/Mac: 啟動 Docker Desktop
# Linux: sudo systemctl start docker
```

### 問題 2: 構建失敗 - "No space left on device"

**原因**：磁碟空間不足

**解決方案**：
```bash
# 清理未使用的映像和容器
docker system prune -a

# 檢查磁碟空間
docker system df
```

### 問題 3: 構建緩慢

**原因**：
- 網路速度慢
- 首次構建需要下載所有依賴

**解決方案**：
- 使用 Docker 緩存（預設啟用）
- 使用本地 Maven 倉庫（如果有的話）
- 在網路較好的環境構建

### 問題 4: 構建失敗 - Maven 錯誤

**原因**：
- 依賴下載失敗
- 網路問題

**解決方案**：
```bash
# 重試構建
docker build --target spring-boot -t hapi-fhir-jpaserver-starter:2025.11.10 .

# 或使用 --no-cache 強制重新下載
docker build --no-cache --target spring-boot -t hapi-fhir-jpaserver-starter:2025.11.10 .
```

### 問題 5: 映像大小過大

**原因**：包含所有構建工具和依賴

**解決方案**：
- 這是正常的，Spring Boot 映像通常約 1GB
- 如果需要更小的映像，可以考慮使用 distroless 版本（需要修改 Dockerfile）

## 驗證構建

### 檢查映像

```bash
# 列出所有映像
docker images hapi-fhir-jpaserver-starter

# 檢查映像詳細資訊
docker inspect hapi-fhir-jpaserver-starter:2025.11.10
```

### 測試運行

```bash
# 運行容器
docker run -d --name hapi-test -p 8080:8080 hapi-fhir-jpaserver-starter:2025.11.10

# 等待服務啟動（約 30 秒）
sleep 30

# 測試健康檢查
curl http://localhost:8080/actuator/health

# 清理測試容器
docker stop hapi-test
docker rm hapi-test
```

## 構建最佳實踐

1. **使用版本標籤**：為每個版本使用唯一的標籤
2. **保留 latest 標籤**：方便使用最新版本
3. **定期清理**：刪除舊的未使用映像
4. **使用緩存**：Docker 會自動使用緩存加速構建
5. **檢查構建日誌**：如有問題，查看詳細構建輸出

## 下一步

構建完成後：

1. 參考 [INSTALLATION.md](INSTALLATION.md) 了解如何安裝和配置
2. 參考 [QUICKSTART.md](QUICKSTART.md) 進行快速部署
3. 參考 [TESTING_AND_SETUP_GUIDE.md](TESTING_AND_SETUP_GUIDE.md) 執行測試

---

**最後更新**: 2025-11-10
