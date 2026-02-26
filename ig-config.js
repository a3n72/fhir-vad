/**
 * 實作指引 (IG) 清單與切換設定
 * 選擇某 IG = 以該 IG 模式送出，不修改 JSON；後端依 X-Vad-IG 轉發或單一多 IG 驗證。
 * - id: 前端與 proxy 辨識用（英文小寫），送出的 X-Vad-IG 表頭
 * - name: 介面顯示名稱
 * - profile: 選填；僅供參考/顯示，不會注入至 JSON
 * - igPackage: 啟動 validator 時用的 -ig 參數（start_validator.py / 文件用）
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
