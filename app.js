const endpointInput = document.getElementById("endpoint");
const pingBtn = document.getElementById("pingBtn");
const pingResult = document.getElementById("pingResult");
const igSelect = document.getElementById("igSelect");
const igHint = document.getElementById("igHint");

const jsonInput = document.getElementById("jsonInput");
const validateTextBtn = document.getElementById("validateTextBtn");
const clearTextBtn = document.getElementById("clearTextBtn");
const textTiming = document.getElementById("textTiming");
const textResult = document.getElementById("textResult");

const fileInput = document.getElementById("fileInput");
const validateFilesBtn = document.getElementById("validateFilesBtn");
const clearFilesBtn = document.getElementById("clearFilesBtn");
const fileList = document.getElementById("fileList");
const filesTiming = document.getElementById("filesTiming");
const filesResult = document.getElementById("filesResult");

const state = {
  files: [],
};

// 從 ig-config.js 的 VAD_IG_CONFIG 填入 IG 下拉選單
const IG_LIST = typeof window.VAD_IG_CONFIG !== "undefined" ? window.VAD_IG_CONFIG : [];
function initIgSelect() {
  IG_LIST.forEach((ig) => {
    const opt = document.createElement("option");
    opt.value = ig.id;
    opt.textContent = ig.name;
    igSelect.appendChild(opt);
  });
  igSelect.addEventListener("change", updateIgHint);
  updateIgHint();
}
function updateIgHint() {
  const id = igSelect.value;
  const ig = IG_LIST.find((x) => x.id === id);
  if (!id || !ig) {
    igHint.textContent = "不注入 profile，依資源內 meta.profile 驗證";
    return;
  }
  if (ig.profile) {
    igHint.textContent = "送出時將注入 meta.profile: " + ig.profile;
  } else {
    igHint.textContent = "此 IG 未設定 profile URL，不注入";
  }
}

/** 依目前選擇的 IG 將 content 轉成要送出的 JSON（必要時注入 meta.profile） */
function preparePayload(content) {
  const id = igSelect.value;
  const ig = IG_LIST.find((x) => x.id === id);
  if (!id || !ig || !ig.profile) return content;
  try {
    const obj = JSON.parse(content);
    if (!obj.meta) obj.meta = {};
    if (!Array.isArray(obj.meta.profile)) obj.meta.profile = [];
    if (!obj.meta.profile.includes(ig.profile)) {
      obj.meta.profile = [ig.profile, ...obj.meta.profile.filter(Boolean)];
    }
    return JSON.stringify(obj);
  } catch (_) {
    return content;
  }
}

function setResult(target, content, isError = false) {
  target.textContent = content;
  if (isError) {
    target.style.borderColor = "#ef4444";
    target.style.background = "#fef2f2";
  } else {
    target.style.borderColor = "#e5e7eb";
    target.style.background = "#f9fafb";
  }
}

function formatJson(text) {
  try {
    const parsed = JSON.parse(text);
    return JSON.stringify(parsed, null, 2);
  } catch (error) {
    return text;
  }
}

async function sendValidation(payload) {
  const endpoint = endpointInput.value.trim();
  if (!endpoint) {
    throw new Error("請先輸入驗證服務位址");
  }

  const headers = {
    "Content-Type": "application/json",
    Accept: "application/fhir+json, application/json",
  };
  const igId = igSelect.value;
  if (igId) headers["X-Vad-IG"] = igId;

  const startedAt = performance.now();
  const response = await fetch(endpoint, {
    method: "POST",
    headers,
    body: payload,
  });

  const text = await response.text();
  const elapsedMs = Math.round(performance.now() - startedAt);
  return {
    ok: response.ok,
    status: response.status,
    body: text,
    elapsedMs,
  };
}

pingBtn.addEventListener("click", async () => {
  pingResult.textContent = "測試中...";
  try {
    const endpoint = endpointInput.value.trim();
    const response = await fetch(endpoint, { method: "OPTIONS" });
    pingResult.textContent = `連線成功：HTTP ${response.status}`;
  } catch (error) {
    pingResult.textContent = `連線失敗：${error.message}`;
  }
});

validateTextBtn.addEventListener("click", async () => {
  const content = jsonInput.value.trim();
  if (!content) {
    setResult(textResult, "請貼上 JSON 內容後再送出", true);
    return;
  }

  validateTextBtn.disabled = true;
  setResult(textResult, "送出中...");
  textTiming.textContent = "";
  try {
    const payload = preparePayload(content);
    const result = await sendValidation(payload);
    const output = [
      `HTTP ${result.status}`,
      "",
      formatJson(result.body),
    ].join("\n");
    setResult(textResult, output, !result.ok);
    textTiming.textContent = `回應時間：${result.elapsedMs} ms`;
  } catch (error) {
    setResult(textResult, `驗證失敗：${error.message}`, true);
    textTiming.textContent = "";
  } finally {
    validateTextBtn.disabled = false;
  }
});

clearTextBtn.addEventListener("click", () => {
  jsonInput.value = "";
  setResult(textResult, "");
  textTiming.textContent = "";
});

fileInput.addEventListener("change", () => {
  state.files = Array.from(fileInput.files || []);
  renderFileList();
});

clearFilesBtn.addEventListener("click", () => {
  fileInput.value = "";
  state.files = [];
  renderFileList();
  setResult(filesResult, "");
  filesTiming.textContent = "";
});

function renderFileList() {
  if (state.files.length === 0) {
    fileList.textContent = "尚未選擇檔案";
    return;
  }

  fileList.innerHTML = "";
  state.files.forEach((file) => {
    const item = document.createElement("div");
    item.className = "file-item";
    item.innerHTML = `<span>${file.name}</span><span class="badge">${(file.size / 1024).toFixed(1)} KB</span>`;
    fileList.appendChild(item);
  });
}

validateFilesBtn.addEventListener("click", async () => {
  if (state.files.length === 0) {
    setResult(filesResult, "請選擇至少一個 JSON 檔案", true);
    return;
  }

  validateFilesBtn.disabled = true;
  setResult(filesResult, "批次送出中...");
  filesTiming.textContent = "";

  const batchStartedAt = performance.now();
  const results = [];
  for (const file of state.files) {
    try {
      const content = await file.text();
      const payload = preparePayload(content);
      const result = await sendValidation(payload);
      results.push({
        name: file.name,
        ok: result.ok,
        status: result.status,
        body: result.body,
        elapsedMs: result.elapsedMs,
      });
    } catch (error) {
      results.push({
        name: file.name,
        ok: false,
        status: "ERROR",
        body: error.message,
        elapsedMs: null,
      });
    }
  }

  const output = results
    .map((item) => {
      const timingText = item.elapsedMs === null ? "" : `, ${item.elapsedMs} ms`;
      const header = `[${item.ok ? "OK" : "FAIL"}] ${item.name} (HTTP ${item.status}${timingText})`;
      const body = formatJson(item.body);
      return `${header}\n${body}`;
    })
    .join("\n\n-------------------------\n\n");

  const hasError = results.some((item) => !item.ok);
  setResult(filesResult, output, hasError);
  const batchElapsed = Math.round(performance.now() - batchStartedAt);
  filesTiming.textContent = `批次總耗時：${batchElapsed} ms`;
  validateFilesBtn.disabled = false;
});

initIgSelect();
renderFileList();
