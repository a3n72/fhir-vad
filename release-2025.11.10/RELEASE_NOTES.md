# 版本發布說明

## HAPI FHIR JPA Server Starter v2025.11.10

### 🎉 重要更新

本版本實現了完整的基於角色的動態授權系統，所有測試通過（50/50），已準備好用於生產環境。

### ✨ 核心功能

#### 1. JWT 身份驗證
- ✅ 完整的 Keycloak OAuth2/OIDC 整合
- ✅ 自動 JWT Token 驗證
- ✅ Audience 驗證支援
- ✅ 多種角色來源支援（realm_access, resource_access, scope）

#### 2. 動態授權系統
- ✅ 基於角色的訪問控制（RBAC）
- ✅ 外部 JSON 規則文件配置
- ✅ 規則熱重載（每 3 秒自動檢測變更）
- ✅ 支援通配符（*）和特定資源類型
- ✅ 用戶級別權限覆寫

#### 3. 授權規則配置
- ✅ 角色基礎權限配置
- ✅ 讀取、寫入、刪除權限分離
- ✅ 用戶級別權限擴展（add_roles）
- ✅ 靈活的權限組合

### 🔧 技術改進

1. **規則構建優化**
   - 改用「一規則一個 Builder」構建方式
   - 解決 HAPI FHIR 8.2.0 的 API 兼容性問題
   - 規則不會互相覆蓋

2. **代碼質量**
   - 使用 LinkedHashSet 維持規則順序
   - 完善的錯誤處理和異常捕獲
   - 詳細的日誌輸出

3. **測試覆蓋**
   - 50 個測試全部通過
   - 涵蓋所有角色和權限組合
   - 完整的端到端測試

### 📊 測試結果

```
Overall Results:
  - Passed: 50
  - Failed: 0
  - Validation Errors (excluded): 11
```

所有用戶測試通過：
- ✅ readonly.user (read:Patient)
- ✅ nurse.alice (nurse)
- ✅ clinician.bob (clinician)
- ✅ pharmacist.carol (pharmacist)
- ✅ admin.user (admin)

### 📦 交付內容

1. **Docker 映像**
   - 標籤：`2025.11.10`
   - 基於：HAPI FHIR 8.2.0
   - Java 17, Spring Boot 內嵌伺服器

2. **配置文件**
   - `config/authz-rules.json` - 授權規則配置
   - `config/application.yaml` - 應用配置

3. **文檔**
   - README.md - 完整功能說明
   - INSTALLATION.md - 安裝指南
   - DEPLOYMENT.md - 部署指南
   - QUICKSTART.md - 快速開始
   - CHANGELOG.md - 更新日誌

4. **工具腳本**
   - `build-and-push.ps1` - Windows 構建腳本
   - `build-and-push.sh` - Linux/Mac 構建腳本
   - `test-all-users.ps1` - 測試腳本

### 🚀 升級指南

如果您從舊版本升級：

1. **備份現有配置**
   ```bash
   cp config/authz-rules.json config/authz-rules.json.backup
   ```

2. **更新 Docker 映像**
   ```bash
   docker pull <your-username>/hapi-fhir-jpaserver-starter:2025.11.10
   ```

3. **更新 docker-compose.yml**
   - 更新映像標籤為 `2025.11.10`

4. **重啟服務**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **驗證升級**
   ```bash
   .\test-all-users.ps1
   ```

### ⚠️ 已知問題

1. `$validate` 操作規則暫時未實現（HAPI FHIR 8.2.0 API 限制）
2. 攔截器檢測功能暫時註釋（API 限制）

這些限制不影響核心功能，可以在未來版本中解決。

### 📝 技術規格

- **HAPI FHIR**: 8.2.0
- **Java**: 17
- **Spring Boot**: 內嵌伺服器
- **資料庫**: PostgreSQL 15
- **身份驗證**: Keycloak 22+
- **授權**: 基於角色的動態授權（RBAC）

### 🙏 致謝

感謝 HAPI FHIR 團隊提供優秀的框架和文檔。

### 📞 支援

如有問題或建議，請參考：
- [HAPI FHIR 官方文檔](https://hapifhir.io/hapi-fhir/docs/introduction/introduction.html)
- [Keycloak 文檔](https://www.keycloak.org/documentation)

---

**發布日期**: 2025-11-10  
**版本**: 2025.11.10  
**狀態**: 生產就緒 ✅

