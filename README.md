# FHIR 批次驗證介面

此介面可直接貼上 JSON 或上傳多個 JSON 檔案，送到本機的 FHIR Validator 進行批次驗證。

## 使用方式

1. 啟動 Validator 服務（第一次會比較久）：

   **建議：** 依 `ig-config.js` 自動帶入所有 IG 並啟動：

   ```bash
   python start_validator.py
   ```

   會讀取 `ig-config.js` 中的 `igPackage`，組出並執行對應的 `java -jar validator_cli.jar server 8080 -ig ...`。若只要看指令不執行，可加 `--dry-run`。其他選項：`--port 8099`、`-tx na`、`--txCache ./fhir-tx-cache`。

   或手動指定單一 IG：

   ```bash
   java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.twcore
   ```

   看到 `HTTP Validation Service listing on port 8080` 即可開始使用。

2. 啟動介面（含本機代理，避免 CORS）：

```
python serve_with_proxy.py
```

3. 用瀏覽器開啟 `http://localhost:5500/index.html`

4. 在介面選擇要驗證的 **實作指引 (IG)**（可選），貼上 JSON 或上傳 JSON 檔案後送出驗證。

---

## Docker 執行

專案內含 `Dockerfile` 與 `docker-compose.yml`，可一鍵啟動 Validator + 網頁介面：

```bash
docker compose up -d
```

- **網頁介面**：http://localhost:5500/
- **Docker Hub 映像**：`dear7601/fhir-vad:latest`（建置後可 `docker push dear7601/fhir-vad:latest` 推送到你的帳號）
- **Validator API**：http://localhost:8080/（供介面轉發，無須直接開啟）

映像建置時會從 [HL7 FHIR Core](https://github.com/hapifhir/org.hl7.fhir.core/releases) 下載 `validator_cli.jar`，並依 `ig-config.js` 載入所有 IG。第一次啟動 validator 會較久（下載 IG／術語等）。

若要關閉術語驗證以加快啟動，可修改 `docker-compose.yml` 中 `validator` 的 `command` 為：

```yaml
command: ["python3", "start_validator.py", "--port", "8080", "-tx", "na"]
```

---

## 多組 IG 切換（PAS / EMR / CI / mCODE / 癌登）

介面支援掛載多組 IG，在「實作指引 (IG)」下拉選單切換。

### 方式一：單一 Validator 掛載多個 IG（建議）

**直接下指令（會自動讀取 ig-config.js）：**

```bash
python start_validator.py
```

會依 `ig-config.js` 內所有 `igPackage` 組出並執行對應的 `-ig` 參數，無須手動列一長串。若要關閉術語或指定快取：

```bash
python start_validator.py -tx na
python start_validator.py --txCache ./fhir-tx-cache
```

- 在介面選擇某個 IG（例如 PAS）時，送出前會**自動注入**該 IG 的 `meta.profile`，無須手動改 JSON。
- 新增/修改 IG 只要編輯 **`ig-config.js`**，下次執行 `start_validator.py` 即會帶入最新清單。

### 方式二：多個 Validator 各跑一個 IG（進階）

若希望每個 IG 獨立一個 process（例如不同埠），可：

1. 分別啟動多個 validator，例如：
   - PAS → `java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.nhi.pas#1.0.9`
   - EMR → `java -jar validator_cli.jar server 8081 -ig tw.gov.mohw.emr`
2. 啟動代理時設定各 IG 的後端（PowerShell 範例）：

   ```powershell
   $env:VAD_BACKEND_PAS = "http://localhost:8080/validateResource"
   $env:VAD_BACKEND_EMR = "http://localhost:8081/validateResource"
   python serve_with_proxy.py
   ```

3. 介面選擇 PAS 或 EMR 時，會帶 `X-Vad-IG` 表頭，proxy 會轉發到對應埠。

---

## 小提示

- 若服務不在 8080，可在介面上調整驗證位址，或設定環境變數 `VAD_BACKEND`。
- 這版 CLI 的驗證端點為 `/validateResource`。
- 批次模式會逐一送出檔案並彙整結果。

---

## 常見問題（FAQ）

### 1. 用 validator 指令能啟動，但「直接開網頁」進不去？

**原因：** 本專案的介面是「網頁 + 代理」兩段式設計，不能直接開 validator 的埠（如 8080 或 8099）。

**正確流程：**

1. 先啟動 **Validator**（例如埠 8080）：
   ```bash
   java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.twcore
   ```
   若使用其他 IG（如 `tw.gov.mohw.nhi.pas#1.0.9`）或要改用其他埠（如 8099），請見下方「改用其他埠」。
2. 再啟動 **介面代理**（固定埠 5500）：
   ```bash
   python serve_with_proxy.py
   ```
3. 用瀏覽器開啟：**http://localhost:5500/** 或 **http://localhost:5500/index.html**  
   不要直接開 `http://localhost:8080`（那是 API，不是操作介面）。

### 2. 我用了 `server 8099`（或其他埠），介面連不到？

**原因：** 代理預設轉送到 `http://localhost:8080/validateResource`。

**做法二選一：**

- **建議：** 啟動 validator 時改用 8080：
  ```bash
  java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.nhi.pas#1.0.9
  ```
- **或** 啟動代理時指定後端位址（Windows PowerShell）：
  ```powershell
  $env:VAD_BACKEND = "http://localhost:8099/validateResource"
  python serve_with_proxy.py
  ```
  （CMD：`set VAD_BACKEND=http://localhost:8099/validateResource` 再執行 `python serve_with_proxy.py`）

介面裡的「驗證服務位址」請保持 **/validateResource**（會透過 5500 的代理轉發到上述後端）。

### 3. 仍然缺 terminology（術語庫）？系統性解法

即使兩邊環境「看起來一樣」，仍可能一邊缺術語、一邊正常，常見原因：**快取路徑不同**、**第一次執行時網路未就緒**、**validator 或 Java 版本差異**。以下為可重現的作法。

#### 選項 A：暫時關閉術語驗證（確認是否僅術語報錯）

若只需要結構與 constraint 驗證、暫不需要 code 與 value set 檢查，可關閉術語伺服器：

```bash
java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.twcore -tx na
```

- `-tx na` 表示不連線術語服務，**不會**驗證 coding/value set，但可排除「缺 terminology」造成的錯誤，方便確認其餘驗證是否正常。

#### 選項 B：指定快取目錄，方便共享（-txCache）

讓快取寫入固定目錄，之後可整包壓縮給其他人或版控：

```bash
java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.twcore -txCache ./fhir-tx-cache
```

- 第一次執行會從術語伺服器下載並寫入 `./fhir-tx-cache`。
- 將整個 `fhir-tx-cache` 資料夾複製到另一台機器**同一相對路徑**，再以相同 `-txCache ./fhir-tx-cache` 啟動，即可共用快取、無須再下載。

#### 選項 C：明確指定術語伺服器（-tx）

若預設連線失敗（例如被防火牆擋），可指定可達的術語伺服器：

```bash
java -jar validator_cli.jar server 8080 -ig tw.gov.mohw.twcore -tx https://tx.fhir.org/r4
```

- 依 FHIR 版本選 `r4` 或 `r5`。若公司有內部術語服務，可改為該 URL。

#### 選項 D：複製已成功的 .fhir 快取（無 -txCache 時）

未使用 `-txCache` 時，validator 使用使用者目錄下的 **`.fhir`**（例如 Windows：`C:\Users\<使用者>\.fhir`）。從**已能正常驗證的機器**壓縮該資料夾，其他人解壓到自己的 `.fhir` 後再啟動，可避免重複下載。若兩邊仍不一致，建議改用品項 B 的 `-txCache` 固定路徑，再共享該資料夾。

### 4. IG 要用哪一個？

- 範例與介面說明寫的是 `tw.gov.mohw.twcore`。
- 若專案規定用 NHI PAS，則使用 `tw.gov.mohw.nhi.pas#1.0.9` 等指定版本即可，**埠號與上述 proxy、網頁進入方式不變**。
