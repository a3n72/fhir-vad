/**
 * 實作指引 (IG) 清單與切換設定
 * - id: 前端與 proxy 辨識用（英文小寫）
 * - name: 介面顯示名稱
 * - profile: 選填；若填寫，送出驗證時會注入 resource.meta.profile 以便依此 IG 驗證
 * - igPackage: 啟動 validator 時用的 -ig 參數（僅供文件/腳本參考）
 */
window.VAD_IG_CONFIG = [
  {
    id: "pas",
    name: "PAS（健保申報）",
    profile: "https://twcore.mohw.gov.tw/ig/twnhi/StructureDefinition/PASPatient",
    igPackage: "tw.gov.mohw.nhi.pas#1.1.1",
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
