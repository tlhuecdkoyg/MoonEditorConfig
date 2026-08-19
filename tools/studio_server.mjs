import http from "node:http";
import { createReadStream, existsSync } from "node:fs";
import { extname, resolve, normalize, relative, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(fileURLToPath(new URL("..", import.meta.url)));
const port = Number(process.env.MOONEDITORCONFIG_PORT || 8765);
const mime = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".md", "text/markdown; charset=utf-8"],
]);

const server = http.createServer((request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    response.writeHead(405, { "Content-Type": "text/plain; charset=utf-8" });
    return response.end("Method not allowed");
  }
  const raw = decodeURIComponent((request.url || "/").split("?")[0]);
  const requestedPath = raw === "/" ? "web/index.html" : raw.replace(/^\/+/, "");
  const file = resolve(root, normalize(requestedPath));
  const fromRoot = relative(root, file);
  if (fromRoot.startsWith("..") || isAbsolute(fromRoot) || !existsSync(file)) {
    response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    return response.end("Not found");
  }
  response.writeHead(200, {
    "Content-Type": mime.get(extname(file).toLowerCase()) || "application/octet-stream",
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": "no-store",
  });
  if (request.method === "HEAD") return response.end();
  createReadStream(file).pipe(response);
});

server.on("error", error => {
  console.error(`无法启动 Studio：${error.message}`);
  process.exitCode = 1;
});

server.listen(port, "127.0.0.1", () => {
  console.log(`MoonEditorConfig Studio: http://127.0.0.1:${port}/web/index.html`);
  console.log("按 Ctrl+C 停止本地服务。");
});
