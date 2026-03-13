/**
 * 實作指引 (IG) 清單與切換設定
 * 選擇某 IG = 以該 IG 模式送出，不修改 JSON；後端依 X-Vad-IG 轉發或單一多 IG 驗證。
 * - id: 前端與 proxy 辨識用（英文小寫），送出的 X-Vad-IG 表頭
 * - name: 介面顯示名稱
 * - profile: 選填；僅供參考/顯示，不會注入至 JSON
 * - igPackage: 啟動 validator 時傳給 -ig 的參數，有兩種寫法：
 *
 *   (1) 本地路徑（自己解壓的 package 資料夾）
 *       寫成「相對於專案根目錄」的路徑，指向「內含 package.json 的那一層」：
 *       例："./igs/pas-1.1.1/package"、"./igs/pas-1.2.1/package"
 *       注意：要指到 package 資料夾本身，不是上一層（不是 ./igs/pas-1.2.1）。
 *
 *   (2) 伺服器／套件庫代號（Validator 啟動時從 HL7/npm 等取得）
 *       寫成「套件 ID」或「套件 ID#版本」：
 *       例："tw.gov.mohw.emr"、"tw.gov.mohw.twcore"、"tw.gov.mohw.nhi.pas#1.2.1"
 *       此時會從 .fhir/packages 或網路下載，無須本地目錄。
 */
window.VAD_IG_CONFIG = [
  {
    id: "pas",
    name: "PAS 1.1.1（健保申報）",
    profile: "https://twcore.mohw.gov.tw/ig/twnhi/StructureDefinition/PASPatient",
    igPackage: "./igs/pas-1.1.1/package",
  },
  {
    id: "pas121",
    name: "PAS 1.2.1（健保申報）",
    profile: "https://twcore.mohw.gov.tw/ig/twnhi/StructureDefinition/PASPatient",
    igPackage: "./igs/pas-1.2.1/package",
  },
  {
    id: "emr",
    name: "EMR（電子病歷）",
    profile: "",
    igPackage: "tw.gov.mohw.emr",
  },
  {
    id: "twcore",
    name: "TW Core（共通）",
    profile: "",
    igPackage: "tw.gov.mohw.twcore",
  },
];
