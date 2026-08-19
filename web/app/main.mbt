///|
extern "js" fn mount_studio(analyze : (String, String) -> String) -> Unit =
  #| (analyze) => {
  #|   const $ = id => document.getElementById(id);
  #|   const source = $("source");
  #|   const target = $("target");
  #|   const status = $("status");
  #|   const escapeHtml = value => String(value ?? "")
  #|     .replaceAll("&", "&amp;").replaceAll("<", "&lt;")
  #|     .replaceAll(">", "&gt;").replaceAll('"', "&quot;");
  #|   let snapshot = null;
  #|   let timer = 0;
  #|   function renderStats(data) {
  #|     $("score").textContent = data.score;
  #|     $("score-ring").style.setProperty("--score", data.score);
  #|     $("section-count").textContent = data.parse.sections;
  #|     $("match-count").textContent = data.matchedSections;
  #|     $("property-count").textContent = data.resolution.properties.length;
  #|     $("diagnostic-count").textContent = data.resolution.diagnostics.length;
  #|   }
  #|   function renderProperties(data) {
  #|     const box = $("properties");
  #|     if (!data.resolution.properties.length) {
  #|       box.innerHTML = '<div class="empty">当前目标没有匹配到任何属性</div>';
  #|       return;
  #|     }
  #|     box.innerHTML = data.resolution.properties.map(item => `
  #|       <article class="property">
  #|         <div><code>${escapeHtml(item.key)}</code><strong>${escapeHtml(item.value)}</strong></div>
  #|         <small>${escapeHtml(item.configPath)} · [${escapeHtml(item.pattern)}] · 第 ${item.source.line} 行</small>
  #|         <details><summary>查看覆盖历史（${item.history.length}）</summary>
  #|           ${item.history.map(step => `<p><b>${escapeHtml(step.action)}</b> ${escapeHtml(step.value)} <span>第 ${step.line} 行 [${escapeHtml(step.pattern)}]</span></p>`).join("")}
  #|         </details>
  #|       </article>`).join("");
  #|   }
  #|   function renderTrace(data) {
  #|     const box = $("trace");
  #|     box.innerHTML = data.resolution.sections.map(item => `
  #|       <button class="trace ${item.matched ? "matched" : "missed"}" data-line="${item.line}">
  #|         <span>${item.matched ? "✓ 匹配" : "· 未匹配"}</span>
  #|         <code>[${escapeHtml(item.pattern)}]</code>
  #|         <small>${escapeHtml(item.reason)}</small>
  #|       </button>`).join("") || '<div class="empty">配置中没有节</div>';
  #|     box.querySelectorAll("[data-line]").forEach(button => button.onclick = () => focusLine(Number(button.dataset.line)));
  #|   }
  #|   function renderDiagnostics(data) {
  #|     const box = $("diagnostics");
  #|     const items = data.resolution.diagnostics;
  #|     if (!items.length) {
  #|       box.innerHTML = '<div class="success">✓ 没有发现问题</div>';
  #|       return;
  #|     }
  #|     box.innerHTML = items.map(item => `
  #|       <button class="diagnostic ${item.severity}" data-line="${item.line}">
  #|         <span>${escapeHtml(item.code)} · 第 ${item.line} 行</span>
  #|         <strong>${escapeHtml(item.message)}</strong>
  #|         <small>${escapeHtml(item.hint)}</small>
  #|       </button>`).join("");
  #|     box.querySelectorAll("[data-line]").forEach(button => button.onclick = () => focusLine(Number(button.dataset.line)));
  #|   }
  #|   function renderLines() {
  #|     const count = Math.max(1, source.value.split("\n").length);
  #|     $("lines").textContent = Array.from({length: count}, (_, i) => i + 1).join("\n");
  #|     $("source-meta").textContent = `${count} 行 · ${new Blob([source.value]).size} 字节`;
  #|   }
  #|   function focusLine(line) {
  #|     const rows = source.value.split("\n");
  #|     const start = rows.slice(0, Math.max(0, line - 1)).reduce((sum, row) => sum + row.length + 1, 0);
  #|     source.focus();
  #|     source.setSelectionRange(start, start + (rows[line - 1] || "").length);
  #|     source.scrollTop = Math.max(0, (line - 3) * 22);
  #|     $("lines").scrollTop = source.scrollTop;
  #|   }
  #|   function run() {
  #|     try {
  #|       snapshot = JSON.parse(analyze(source.value, target.value.trim() || "src/main.mbt"));
  #|       renderStats(snapshot); renderProperties(snapshot); renderTrace(snapshot);
  #|       renderDiagnostics(snapshot); renderLines();
  #|       status.textContent = "MoonBit 分析引擎已就绪";
  #|       status.className = "status ready";
  #|     } catch (error) {
  #|       console.error(error); status.textContent = `分析失败：${error.message}`;
  #|       status.className = "status error";
  #|     }
  #|   }
  #|   function schedule() {
  #|     clearTimeout(timer); status.textContent = "正在分析…"; status.className = "status busy";
  #|     timer = setTimeout(run, 80);
  #|   }
  #|   function download(name, content, type) {
  #|     const link = document.createElement("a");
  #|     link.href = URL.createObjectURL(new Blob([content], {type})); link.download = name; link.click();
  #|     setTimeout(() => URL.revokeObjectURL(link.href), 1000);
  #|   }
  #|   source.addEventListener("input", schedule); target.addEventListener("input", schedule);
  #|   source.addEventListener("scroll", () => $("lines").scrollTop = source.scrollTop);
  #|   $("format").onclick = () => { if (snapshot) { source.value = snapshot.formatted; schedule(); } };
  #|   $("copy").onclick = async () => { await navigator.clipboard.writeText(source.value); $("copy").textContent = "已复制"; setTimeout(() => $("copy").textContent = "复制", 1000); };
  #|   $("export").onclick = () => snapshot && download("mooneditorconfig-analysis.json", JSON.stringify(snapshot, null, 2), "application/json");
  #|   $("theme").onclick = () => { document.documentElement.classList.toggle("light"); localStorage.setItem("mec-theme", document.documentElement.classList.contains("light") ? "light" : "dark"); };
  #|   document.querySelectorAll("[data-example]").forEach(button => button.onclick = () => {
  #|     const examples = {
  #|       moonbit: `root = true\n\n[*]\ncharset = utf-8\nend_of_line = lf\ninsert_final_newline = true\n\n[*.mbt]\nindent_style = space\nindent_size = 2\n\n[src/**.mbt]\nmax_line_length = 100\n`,
  #|       hierarchy: `root = true\n\n[*]\nindent_style = space\nindent_size = 4\n\n[{package,src}/**.{mbt,md}]\nindent_size = 2\ntrim_trailing_whitespace = true\n\n[test/**]\nmax_line_length = unset\n`,
  #|       broken: `root = maybe\nindent_size = 0\n\n[]\nindent_style = tabs\n\n[*.mbt\ncharset = utf32\n`,
  #|     };
  #|     source.value = examples[button.dataset.example]; schedule();
  #|   });
  #|   if (localStorage.getItem("mec-theme") === "light") document.documentElement.classList.add("light");
  #|   run();
  #| }

///|
fn main {
  mount_studio(@lib.studio_snapshot)
}
