# HAPI FHIR JPA Server Starter - Release 2025.11.10

`release-2025.11.10` 是一個可直接部署的 HAPI FHIR 交付包，內含 Docker Compose、應用設定、授權規則、測試腳本與完整文件。此版本可用兩種模式運行：

- `SECURITY_JWT_ENABLED=true`：啟用 Keycloak/JWT 驗證與角色授權
- `SECURITY_JWT_ENABLED=false`：關閉驗證，作為一般 FHIR Server 使用

## 一頁掌握

- **版本號**：`2025.11.10`
- **HAPI FHIR**：`8.2.0`
- **Java**：`17`
- **預設部署方式**：Docker Compose
- **預設 FHIR Base URL**：`http://localhost:8080/fhir`
- **預設 Keycloak 管理介面**：`http://localhost:8084`
- **測試結果**：`50/50` 通過

## 這套系統是什麼

這套系統以 `HAPI FHIR JPA Server` 為核心，搭配 PostgreSQL 作為資料庫；若啟用驗證模式，則再整合 Keycloak 做 JWT 驗證，並由 HAPI 內的授權攔截器依 `config/authz-rules.json` 決定不同角色可讀、可寫、可刪除的 FHIR 資源。

### 核心能力

- 支援標準 FHIR R4 API
- 支援 PostgreSQL 儲存
- 支援 Keycloak OAuth2/OIDC JWT 驗證
- 支援 `audience` 驗證
- 支援以 JSON 定義角色授權規則
- 支援規則熱重載
- 支援完整角色權限測試

## 系統架構

### 元件關係

```text
Client / Postman / App
        |
        |  HTTP :8080
        v
   HAPI FHIR Server
        |
        |-- 讀寫 PostgreSQL (pg-hapi)
        |
        |-- 讀取 config/application.yaml
        |-- 讀取 config/authz-rules.json
        |
        `-- (JWT 模式下) 驗證 Bearer Token
                 |
                 v
              Keycloak
                 |
                 `-- PostgreSQL (pg-keycloak)
```

### Docker Compose 內的服務

- `pg-hapi`：HAPI FHIR 使用的 PostgreSQL
- `hapi`：FHIR API 主服務
- `pg-keycloak`：Keycloak 使用的 PostgreSQL
- `keycloak`：OIDC / JWT 驗證服務

### 設定檔與執行流程

- `docker-compose.yml`：決定要啟動哪些容器、環境變數與映像版本
- `.env`：放資料庫、埠號、Realm 與 JWT 開關等可覆寫值
- `config/application.yaml`：HAPI FHIR 與 Spring Boot 應用設定
- `config/authz-rules.json`：角色與資源權限規則

## 你應該先看哪份文件

### 建議閱讀順序

1. 先讀本檔 `README.md`
2. 想快速啟動就讀 `QUICKSTART.md`
3. 要完整安裝流程就讀 `INSTALLATION.md`
4. 要啟用 JWT/Keycloak 就讀 `KEYCLOAK_SETUP.md`
5. 要完整測試與排錯就讀 `TESTING_AND_SETUP_GUIDE.md`
6. 要部署到正式環境就讀 `DEPLOYMENT.md`
7. 要看版本差異就讀 `RELEASE_NOTES.md` 與 `CHANGELOG.md`

### 不同角色的閱讀路徑

- **系統管理員 / DevOps**：`README.md` -> `INSTALLATION.md` -> `DEPLOYMENT.md`
- **API 使用者 / 前端 / 串接方**：`README.md` -> `QUICKSTART.md`
- **Keycloak 管理者**：`README.md` -> `KEYCLOAK_SETUP.md` -> `TESTING_AND_SETUP_GUIDE.md`
- **除錯人員**：`README.md` -> `TESTING_AND_SETUP_GUIDE.md` -> `TROUBLESHOOTING.md`

## 目錄導覽

### 主要文件

- `README.md`：總覽、架構、使用方式、文件地圖
- `INDEX.md`：交付文件索引
- `QUICKSTART.md`：快速啟動
- `INSTALLATION.md`：完整安裝
- `DEPLOYMENT.md`：部署說明
- `KEYCLOAK_SETUP.md`：Keycloak 設定
- `TESTING_AND_SETUP_GUIDE.md`：測試與排錯
- `TROUBLESHOOTING.md`：常見問題
- `RELEASE_NOTES.md`：本版重點
- `CHANGELOG.md`：更新明細

### 主要檔案

- `docker-compose.yml`：本版實際部署檔
- `docker-compose.example.yml`：映像部署範例
- `.env`：本地部署環境變數
- `config/application.yaml`：HAPI 主設定
- `config/authz-rules.json`：授權規則
- `test-all-users.ps1`：整體授權測試腳本
- `build-and-push.ps1` / `build-and-push.sh`：建置與推送映像

## 兩種運作模式

### 模式 A：一般 FHIR Server（不驗證）

適用於：

- 本機開發
- 內網測試
- 暫時不接 Keycloak 的情境

設定方式：

```env
SECURITY_JWT_ENABLED=false
```

此模式下：

- 不需 Bearer Token
- 可直接呼叫 `http://localhost:8080/fhir/...`
- 可不啟動 `keycloak` 與 `pg-keycloak`

### 模式 B：JWT 驗證 + 角色授權

適用於：

- 需要登入驗證
- 需要依角色限制 FHIR 權限
- 正式或接近正式的測試環境

設定方式：

```env
SECURITY_JWT_ENABLED=true
```

此模式下：

- `/fhir/**` 需 Bearer Token
- HAPI 會以 `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI` 驗證 JWT
- 若 `SECURITY_JWT_VALIDATE_AUDIENCE=true`，Token 的 `aud` 必須符合 `SECURITY_JWT_ACCEPTED_AUDIENCES`
- HAPI 會依 `config/authz-rules.json` 判斷角色是否可讀寫資源

## 快速開始

### 前置需求

- Docker Desktop 或 Docker Engine
- `docker compose` 可用
- Windows PowerShell（若要跑 `.ps1` 測試腳本）

### 步驟 1：進入交付目錄

```powershell
cd .\release-2025.11.10
```

### 步驟 2：確認 `.env`

本目錄已附 `.env`。請至少確認以下項目：

- `PG_HAPI_DB`
- `PG_HAPI_USER`
- `PG_HAPI_PASS`
- `PG_KC_DB`
- `PG_KC_USER`
- `PG_KC_PASS`
- `KC_EXTERNAL_PORT`
- `REALM`
- `SECURITY_JWT_ENABLED`

如果你要對外使用，請務必將 `.env` 內目前的示範密碼與 secret 換成正式值。

### 步驟 3：選擇啟動模式

#### 啟動一般 FHIR Server

```powershell
# .env 中設定 SECURITY_JWT_ENABLED=false
docker compose up -d pg-hapi hapi
```

#### 啟動 JWT + Keycloak 模式

```powershell
# .env 中設定 SECURITY_JWT_ENABLED=true
docker compose up -d
```

### 步驟 4：確認服務正常

```powershell
docker compose ps
docker compose logs -f hapi
```

健康檢查：

```powershell
curl http://localhost:8080/actuator/health
```

## 啟用 IG（Implementation Guide）

本版預設未啟用任何 IG。若要讓 HAPI 在啟動時載入指定 IG，請修改 `config/application.yaml` 的 `hapi.fhir.implementationguides`。

### 基本做法

```yaml
hapi:
  fhir:
    ig_runtime_upload_enabled: false
    implementationguides:
      tw_pas:
        name: tw.gov.mohw.nhi.pas
        version: 1.2.0
        installMode: STORE
        fetchDependencies: true
```

說明：

- `ig_runtime_upload_enabled: false` 與 `implementationguides` 不衝突；前者是關閉執行期上傳，後者是啟動時載入既定 IG
- `installMode: STORE` 建議作為預設值，可降低部分 `StructureDefinition` 安裝時的驗證警示
- 若你需要把 package 內容實際安裝進伺服器，再改用 `STORE_AND_INSTALL`
- `fetchDependencies: true` 會自動抓取相依套件

### PAS IG 範例

若要啟用臺灣健保事前審查 IG，可使用：

```yaml
implementationguides:
  tw_core:
    name: tw.gov.mohw.twcore
    version: 0.3.2
    installMode: STORE
    fetchDependencies: true
  tw_pas:
    name: tw.gov.mohw.nhi.pas
    version: 1.2.0
    installMode: STORE
    fetchDependencies: true
```

參考資料：

- [臺灣健保事前審查實作指引（PAS IG）](https://nhicore.nhi.gov.tw/pas/)

### Docker Compose 建議

若要載入較大的 IG，建議在 `docker-compose.yml` 的 `hapi` service 補上 JVM 記憶體與 package cache：

```yaml
hapi:
  environment:
    JAVA_TOOL_OPTIONS: "-Xms2g -Xmx8g"
  volumes:
    - ./config:/app/config:ro
    - fhir_pkg_cache:/root/.fhir/packages
```

說明：

- `JAVA_TOOL_OPTIONS` 用來提高 JVM heap，避免安裝大型 IG 時出現 `Java heap space`
- `fhir_pkg_cache` 是 Docker named volume，不需要先在主機建立資料夾
- 若容器重建頻繁，保留 package cache 可避免重複下載相同 IG

### 套用變更

修改 `application.yaml` 或 `docker-compose.yml` 後，可重新建立 `hapi`：

```powershell
docker compose down
docker compose up -d hapi
docker compose logs -f hapi
```

若只是調整 `config/application.yaml`，通常不需要重 build image。

## 常用 API

### 一般檢查

- `GET http://localhost:8080/actuator/health`
- `GET http://localhost:8080/fhir/metadata`

### 一般 FHIR Server 模式

```powershell
curl http://localhost:8080/fhir/Patient
```

### JWT 驗證模式

```powershell
curl -H "Authorization: Bearer <token>" http://localhost:8080/fhir/metadata
```

## 授權規則怎麼看

授權規則在 `config/authz-rules.json`，基本結構如下：

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

### 目前內建角色示例

- `admin`：所有資源可讀寫刪
- `clinician`：可讀多種臨床資源，並可寫部分資源
- `nurse`：可讀 `Patient`、`Observation`、`Encounter`，可寫 `Observation`
- `pharmacist`：偏藥事相關資源
- `read:*` / `write:*` 型角色：細粒度控制特定資源

### 規則變更方式

1. 編輯 `config/authz-rules.json`
2. 儲存檔案
3. HAPI 會自動重新載入規則

## 重要設定說明

### `docker-compose.yml`

此檔負責：

- 指定 HAPI 映像版本 `dear7601/hapi-fhir-jpaserver-starter:2025.11.10`
- 掛載 `./config` 到容器內 `/app/config`
- 可選擇掛載 `fhir_pkg_cache` 到 `/root/.fhir/packages` 以保留 IG package 快取
- 可透過 `JAVA_TOOL_OPTIONS` 提高 HAPI JVM heap
- 傳入資料庫連線與 JWT 相關環境變數
- 透過 `SECURITY_JWT_ENABLED` 切換驗證開關

### `config/application.yaml`

此檔負責：

- 設定 HAPI FHIR 版本為 `R4`
- 啟用 OpenAPI
- 設定資料庫預設值
- 設定 `implementationguides` 以載入 TW Core、PAS 等 IG
- 以 `ig_runtime_upload_enabled` 控制是否開放執行期上傳 IG
- 啟用請求驗證 `requests_enabled: true`
- 註冊自訂授權攔截器套件

### `.env`

`.env` 主要用來覆寫：

- PostgreSQL 帳密
- Keycloak Realm
- Keycloak 對外埠號
- JWT 驗證開關
- 其他整合所需 secret

### 常用環境變數

| 變數 | 用途 | 建議 |
|---|---|---|
| `SECURITY_JWT_ENABLED` | 是否啟用 JWT 驗證 | 本機測試可 `false`，正式建議 `true` |
| `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI` | JWT 驗證 JWK 端點 | JWT 模式必填 |
| `SECURITY_JWT_VALIDATE_AUDIENCE` | 是否驗 `aud` | 正式建議 `true` |
| `SECURITY_JWT_ACCEPTED_AUDIENCES` | 可接受的 audience | 需與 Keycloak mapper 一致 |
| `AUTHZ_RULES_PATH` | 授權規則檔路徑 | 預設即可 |
| `PG_HAPI_DB` / `PG_HAPI_USER` / `PG_HAPI_PASS` | HAPI 資料庫設定 | 依環境調整 |
| `PG_KC_DB` / `PG_KC_USER` / `PG_KC_PASS` | Keycloak 資料庫設定 | 依環境調整 |
| `REALM` | Keycloak Realm 名稱 | 預設 `fhir-realm` |
| `KC_EXTERNAL_PORT` | Keycloak 對外埠號 | 預設 `8084` |

## 驗證模式的最小操作流程

1. 在 `.env` 設定 `SECURITY_JWT_ENABLED=true`
2. 啟動 `docker compose up -d`
3. 依 `KEYCLOAK_SETUP.md` 建立 `Realm`、`Client`、`Audience Mapper`、角色與測試用戶
4. 取得 Token
5. 以 Bearer Token 呼叫 `http://localhost:8080/fhir/...`
6. 執行 `.\test-all-users.ps1` 驗證權限

## 一般 FHIR Server 模式的最小操作流程

1. 在 `.env` 設定 `SECURITY_JWT_ENABLED=false`
2. 啟動 `docker compose up -d pg-hapi hapi`
3. 呼叫 `http://localhost:8080/fhir/metadata`
4. 直接使用 FHIR API，不需 Token

## 測試與驗收

### 內建測試腳本

```powershell
.\test-all-users.ps1
```

此腳本主要驗證：

- 不同角色的讀取權限
- 不同角色的寫入權限
- 權限拒絕是否正確
- 驗證錯誤是否被正確排除

### 建議驗收清單

- HAPI 容器可正常啟動
- `actuator/health` 回應正常
- `fhir/metadata` 可正常存取
- JWT 模式下，無 Token 時應收到 `401`
- JWT 模式下，不符權限時應收到 `403`
- 一般模式下，可不帶 Token 直接存取 FHIR API
- 規則檔修改後可自動生效

## 常見操作指令

### 啟動

```powershell
docker compose up -d
```

### 只啟動一般 FHIR Server 所需服務

```powershell
docker compose up -d pg-hapi hapi
```

### 看日誌

```powershell
docker compose logs -f hapi
docker compose logs -f keycloak
```

### 停止

```powershell
docker compose down
```

### 重新啟動

```powershell
docker compose down
docker compose up -d
```

## 文件地圖

| 文件 | 何時閱讀 | 你會得到什麼 |
|---|---|---|
| `README.md` | 第一次接手此版本時 | 系統總覽、架構、模式、操作入口 |
| `INDEX.md` | 想快速找文件時 | 文件全覽索引 |
| `QUICKSTART.md` | 想最短時間跑起來時 | 快速部署步驟 |
| `INSTALLATION.md` | 想完整安裝與初始化時 | 詳細安裝流程 |
| `KEYCLOAK_SETUP.md` | 要啟用 JWT 驗證時 | Realm、Client、Mapper、角色設定 |
| `TESTING_AND_SETUP_GUIDE.md` | 要驗證整套權限與排錯時 | 測試腳本與故障排查 |
| `TROUBLESHOOTING.md` | 出現異常時 | 常見錯誤與修正方式 |
| `DEPLOYMENT.md` | 要交付或上線時 | 映像、部署與維運說明 |
| `RELEASE_NOTES.md` | 想看本版重點時 | 版本成果摘要 |
| `CHANGELOG.md` | 想看細部變更時 | 詳細更新記錄 |

## 已知事項

- HAPI 請求驗證已啟用，所以某些建立資源請求若內容不符合 FHIR 規範，可能會回 `400` 或 `422`
- `$validate` 相關授權規則仍有 HAPI 8.2.0 API 限制
- JWT 模式若啟用 audience 驗證，Keycloak 必須正確配置 mapper
- `.env` 目前附的是部署樣本值，正式環境請改為安全密碼與 secret

## 相關外部文件

- [HAPI FHIR 官方文件](https://hapifhir.io/hapi-fhir/docs/introduction/introduction.html)
- [Keycloak 文件](https://www.keycloak.org/documentation)

## 授權

本專案基於 Apache License 2.0 授權。

