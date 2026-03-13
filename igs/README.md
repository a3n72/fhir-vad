# 本地 IG Package 放置說明

此目錄用於放置 **TWPAS** 等實作指引的本地 package，供 Validator 啟動時載入（無須每次從網路下載）。

## 目錄結構

解壓完成後應為：

```
igs/
├── pas-1.1.1/
│   └── package/          ← 1.1.1 的 package.tgz 解壓後得到的 package 資料夾
├── pas-1.2.1/
│   └── package/          ← 1.2.1 的 package.tgz 解壓後得到的 package 資料夾
└── README.md（本檔）
```

## 如何從 package.tgz 還原成 package 資料夾

下載的 `package.tgz` 需解壓**兩次**（先得到 `package.tar`，再得到 `package` 資料夾）。

### 方式一：使用本專案提供的腳本（建議）

在專案根目錄執行 PowerShell：

```powershell
# PAS 1.1.1：請先將對應的 package.tgz 放在專案目錄或指定路徑
.\igs\extract_pas_package.ps1 -TgzPath ".\path\to\pas-1.1.1-package.tgz" -Version "pas-1.1.1"

# PAS 1.2.1
.\igs\extract_pas_package.ps1 -TgzPath ".\path\to\pas-1.2.1-package.tgz" -Version "pas-1.2.1"
```

腳本會自動建立 `igs\<Version>\package` 並解壓。

### 方式二：手動解壓

1. 將 `package.tgz` 解壓一次 → 得到 `package.tar`
2. 再將 `package.tar` 解壓一次 → 得到 `package` 資料夾
3. 把該 `package` 資料夾**整個**放到對應版本目錄下：
   - PAS 1.1.1 → `igs\pas-1.1.1\package\`
   - PAS 1.2.1 → `igs\pas-1.2.1\package\`

Windows 10+ 可在檔案總管對 `.tgz` / `.tar` 按右鍵「解壓縮」，或使用：

```powershell
tar -xzf package.tgz
tar -xf package.tar
move package igs\pas-1.1.1\
```

## 驗證與介面

- 本專案 `ig-config.js` 已設定 **PAS 1.1.1** 與 **PAS 1.2.1** 兩組選項，皆指向上述本地路徑。
- 啟動 Validator（本機或 Docker）後，在網頁介面「實作指引 (IG)」下拉選單可切換兩版進行測試。
- 若未放置本地 package，可改回使用遠端套件名稱（如 `tw.gov.mohw.nhi.pas#1.1.1`），需在 `ig-config.js` 中將對應項目的 `igPackage` 改回該字串。
