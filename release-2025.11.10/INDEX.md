# 交付文件索引

## 📦 版本資訊

- **版本號**: 2025.11.10
- **構建日期**: 2025-11-10
- **狀態**: 生產就緒 ✅

## 📄 文檔文件

### 主要文檔
- **[README.md](README.md)** - 完整功能說明和使用指南
- **[RELEASE_NOTES.md](RELEASE_NOTES.md)** - 版本發布說明和更新內容
- **[CHANGELOG.md](CHANGELOG.md)** - 詳細更新日誌

### 安裝和部署
- **[安裝內容-2025.11.10.md](安裝內容-2025.11.10.md)** - 本版安裝內容清單與安裝步驟（含 Windows Server / Docker Engine）
- **[INSTALLATION.md](INSTALLATION.md)** - 詳細安裝指南
- **[QUICKSTART.md](QUICKSTART.md)** - 5 分鐘快速開始指南
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - 生產環境部署指南

### 測試和設置
- **[TESTING_AND_SETUP_GUIDE.md](TESTING_AND_SETUP_GUIDE.md)** - 完整的測試與設置指南（包含 Keycloak 設置、測試腳本使用、排錯）
- **[KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md)** - Keycloak 完整設置指南
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 故障排除指南（包含我們遇到的 QA 問題與解決方案）

### 配置文件
- **[config/authz-rules.json](config/authz-rules.json)** - 授權規則配置範例
- **[config/application.yaml](config/application.yaml)** - 應用配置文件
- **[docker-compose.example.yml](docker-compose.example.yml)** - Docker Compose 配置範例

## 🛠️ 工具腳本

### 構建和推送
- **[build-and-push.ps1](build-and-push.ps1)** - Windows PowerShell 構建和推送腳本
- **[build-and-push.sh](build-and-push.sh)** - Linux/Mac Bash 構建和推送腳本

### 測試
- **[test-all-users.ps1](test-all-users.ps1)** - 完整授權測試腳本

## 📋 快速參考

### 開始使用
1. 閱讀 [安裝內容-2025.11.10.md](安裝內容-2025.11.10.md) 或 [QUICKSTART.md](QUICKSTART.md) 進行快速部署
2. 參考 [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) 設置 Keycloak
3. 參考 [TESTING_AND_SETUP_GUIDE.md](TESTING_AND_SETUP_GUIDE.md) 執行測試
4. 查看 [README.md](README.md) 了解完整功能

### 遇到問題？
1. 查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 了解常見問題和解決方案
2. 參考 [TESTING_AND_SETUP_GUIDE.md](TESTING_AND_SETUP_GUIDE.md) 中的排錯章節

### 部署到生產環境
1. 閱讀 [DEPLOYMENT.md](DEPLOYMENT.md)
2. 配置環境變數和授權規則
3. 使用提供的構建腳本構建和推送映像

### 構建和推送 Docker 映像

**Windows:**
```powershell
.\build-and-push.ps1 -DockerHubUsername <your-username> -DockerHubPassword <your-password>
```

**Linux/Mac:**
```bash
chmod +x build-and-push.sh
./build-and-push.sh <your-username> <your-password>
```

## 🔍 文件結構

```
release-2025.11.10/
├── README.md                    # 主要說明文檔
├── RELEASE_NOTES.md             # 版本發布說明
├── CHANGELOG.md                 # 更新日誌
├── 安裝內容-2025.11.10.md       # 本版安裝內容與步驟
├── INSTALLATION.md              # 安裝指南
├── QUICKSTART.md                # 快速開始
├── DEPLOYMENT.md                # 部署指南
├── TESTING_AND_SETUP_GUIDE.md  # 測試與設置完整指南
├── KEYCLOAK_SETUP.md            # Keycloak 設置指南
├── TROUBLESHOOTING.md           # 故障排除指南
├── BUILD_INSTRUCTIONS.md        # 構建說明
├── INDEX.md                     # 本文件（索引）
├── DELIVERY_SUMMARY.md          # 交付總結
├── VERSION.txt                  # 版本資訊
├── config/                      # 配置文件目錄
│   ├── authz-rules.json        # 授權規則配置
│   └── application.yaml        # 應用配置
├── build-and-push.ps1          # Windows 構建腳本
├── build-and-push.sh            # Linux/Mac 構建腳本
├── docker-compose.example.yml  # Docker Compose 範例
└── test-all-users.ps1          # 測試腳本
```

## ✅ 驗證清單

部署前請確認：

- [ ] 已閱讀 [QUICKSTART.md](QUICKSTART.md)
- [ ] 已閱讀 [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) 並完成 Keycloak 設置
- [ ] 已配置環境變數（.env 文件）
- [ ] 已配置授權規則（config/authz-rules.json）
- [ ] 所有測試用戶已創建並配置
- [ ] 資料庫連接正常
- [ ] 已執行測試腳本（test-all-users.ps1）驗證功能
- [ ] 如遇問題，已參考 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 📞 技術支援

- [HAPI FHIR 官方文檔](https://hapifhir.io/hapi-fhir/docs/introduction/introduction.html)
- [Keycloak 文檔](https://www.keycloak.org/documentation)

---

**版本**: 2025.11.10  
**最後更新**: 2025-11-10

