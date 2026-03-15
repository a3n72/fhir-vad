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
    igHint.textContent = "請選擇要驗證的 IG，送出時不修改 JSON";
    return;
  }
  igHint.textContent = "以「" + ig.name + "」模式送出（不修改 JSON，依後端該 IG 驗證）";
}

/** 切換 IG 模式：不注入 profile，原樣送出。後端依 X-Vad-IG 或單一多 IG 環境驗證。 */
function preparePayload(content) {
  return content;
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (char) => {
    const map = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    };
    return map[char];
  });
}

function setResultText(target, content, isError = false) {
  target.textContent = content;
  target.classList.remove("result-rich");
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

function tryParseJson(text) {
  try {
    return JSON.parse(text);
  } catch (error) {
    return null;
  }
}

function normalizeSeverity(severity) {
  if (severity === "fatal" || severity === "error") return "error";
  if (severity === "warning") return "warning";
  return "information";
}

function getIssueText(issue) {
  return (
    issue?.details?.text ||
    issue?.diagnostics ||
    issue?.details?.coding?.[0]?.display ||
    "未提供說明"
  );
}

function renderIssueList(issues) {
  if (issues.length === 0) {
    return '<div class="outcome-empty">無</div>';
  }

  return issues
    .map((issue) => {
      const paths = [...(issue.expression || []), ...(issue.location || [])];
      const pathText = paths.length ? paths.join(", ") : "";
      const details = [];
      if (issue.code) details.push(`代碼：${issue.code}`);
      if (pathText) details.push(`位置：${pathText}`);
      if (issue.source) details.push(`來源：${issue.source}`);
      return `
        <div class="outcome-issue">
          <div class="outcome-issue-main">${escapeHtml(getIssueText(issue))}</div>
          ${
            details.length
              ? `<div class="outcome-issue-meta">${escapeHtml(details.join(" ｜ "))}</div>`
              : ""
          }
        </div>
      `;
    })
    .join("");
}

function buildOutcomeHtml(title, result, parsed) {
  const issues = Array.isArray(parsed?.issue) ? parsed.issue : [];
  const grouped = {
    error: [],
    warning: [],
    information: [],
  };

  issues.forEach((issue) => {
    grouped[normalizeSeverity(issue.severity)].push(issue);
  });

  const totalIssues = issues.length;
  const hasProblem = grouped.error.length > 0 || !result.ok;
  const formattedJson = escapeHtml(JSON.stringify(parsed, null, 2));

  return `
    <section class="outcome-card">
      <div class="outcome-header">
        <div>
          <div class="outcome-title">${escapeHtml(title)}</div>
          <div class="outcome-subtitle">HTTP ${result.status}${
            result.elapsedMs == null ? "" : ` ｜ ${result.elapsedMs} ms`
          } ｜ 共 ${totalIssues} 筆 issue</div>
        </div>
        <div class="outcome-badges">
          <span class="severity-pill ${hasProblem ? "error" : "success"}">
            ${hasProblem ? "需處理" : "通過"}
          </span>
          <span class="severity-pill error">Error ${grouped.error.length}</span>
          <span class="severity-pill warning">Warning ${grouped.warning.length}</span>
          <span class="severity-pill information">Info ${grouped.information.length}</span>
        </div>
      </div>
      <div class="outcome-groups">
        <div class="severity-group error">
          <div class="severity-group-title">Error / Fatal</div>
          ${renderIssueList(grouped.error)}
        </div>
        <div class="severity-group warning">
          <div class="severity-group-title">Warning</div>
          ${renderIssueList(grouped.warning)}
        </div>
        <div class="severity-group information">
          <div class="severity-group-title">Information</div>
          ${renderIssueList(grouped.information)}
        </div>
      </div>
      <details class="outcome-raw">
        <summary>原始 OperationOutcome JSON</summary>
        <pre>${formattedJson}</pre>
      </details>
    </section>
  `;
}

function renderPlainResult(target, title, result) {
  target.classList.add("result-rich");
  target.style.borderColor = result.ok ? "#e5e7eb" : "#ef4444";
  target.style.background = result.ok ? "#f9fafb" : "#fef2f2";
  target.innerHTML = `
    <section class="outcome-card">
      <div class="outcome-header">
        <div>
          <div class="outcome-title">${escapeHtml(title)}</div>
          <div class="outcome-subtitle">HTTP ${escapeHtml(result.status)}${
            result.elapsedMs == null ? "" : ` ｜ ${result.elapsedMs} ms`
          }</div>
        </div>
      </div>
      <pre class="outcome-plain">${escapeHtml(formatJson(result.body))}</pre>
    </section>
  `;
}

function renderValidationResult(target, title, result) {
  const parsed = tryParseJson(result.body);
  if (parsed?.resourceType === "OperationOutcome") {
    target.classList.add("result-rich");
    const hasProblem =
      !result.ok ||
      (Array.isArray(parsed.issue) &&
        parsed.issue.some((issue) => normalizeSeverity(issue.severity) === "error"));
    target.style.borderColor = hasProblem ? "#ef4444" : "#e5e7eb";
    target.style.background = hasProblem ? "#fff7f7" : "#f8fafc";
    target.innerHTML = buildOutcomeHtml(title, result, parsed);
    return;
  }

  renderPlainResult(target, title, result);
}

function renderBatchResults(target, results) {
  const hasError = results.some((item) => !item.ok);
  target.classList.add("result-rich");
  target.style.borderColor = hasError ? "#ef4444" : "#e5e7eb";
  target.style.background = hasError ? "#fff7f7" : "#f8fafc";
  target.innerHTML = results
    .map((item) => {
      const parsed = tryParseJson(item.body);
      if (parsed?.resourceType === "OperationOutcome") {
        return buildOutcomeHtml(item.name, item, parsed);
      }
      return `
        <section class="outcome-card">
          <div class="outcome-header">
            <div>
              <div class="outcome-title">${escapeHtml(item.name)}</div>
              <div class="outcome-subtitle">HTTP ${escapeHtml(item.status)}${
                item.elapsedMs == null ? "" : ` ｜ ${item.elapsedMs} ms`
              }</div>
            </div>
          </div>
          <pre class="outcome-plain">${escapeHtml(formatJson(item.body))}</pre>
        </section>
      `;
    })
    .join("");
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
    setResultText(textResult, "請貼上 JSON 內容後再送出", true);
    return;
  }

  validateTextBtn.disabled = true;
  setResultText(textResult, "送出中...");
  textTiming.textContent = "";
  try {
    const payload = preparePayload(content);
    const result = await sendValidation(payload);
    renderValidationResult(textResult, "本次驗證結果", result);
    textTiming.textContent = `回應時間：${result.elapsedMs} ms`;
  } catch (error) {
    setResultText(textResult, `驗證失敗：${error.message}`, true);
    textTiming.textContent = "";
  } finally {
    validateTextBtn.disabled = false;
  }
});

clearTextBtn.addEventListener("click", () => {
  jsonInput.value = "";
  setResultText(textResult, "");
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
  setResultText(filesResult, "");
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
    setResultText(filesResult, "請選擇至少一個 JSON 檔案", true);
    return;
  }

  validateFilesBtn.disabled = true;
  setResultText(filesResult, "批次送出中...");
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

  renderBatchResults(filesResult, results);
  const batchElapsed = Math.round(performance.now() - batchStartedAt);
  filesTiming.textContent = `批次總耗時：${batchElapsed} ms`;
  validateFilesBtn.disabled = false;
});

initIgSelect();
renderFileList();
