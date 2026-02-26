import http.server
import os
import urllib.error
import urllib.request

# 單一後端（預設）
BACKEND_URL = os.environ.get(
    "VAD_BACKEND", "http://localhost:8080/validateResource"
)

# 多組 IG 對應不同後端（選用）：VAD_BACKEND_PAS, VAD_BACKEND_EMR, VAD_BACKEND_CI, ...
def _get_backend_for_ig(ig_id: str):
    if not ig_id:
        return None
    key = f"VAD_BACKEND_{ig_id.upper().replace('-', '_')}"
    return os.environ.get(key)


class ProxyHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Headers", "Content-Type, Accept, X-Vad-IG"
        )
        self.send_header(
            "Access-Control-Allow-Methods", "POST, OPTIONS"
        )
        super().end_headers()

    def do_OPTIONS(self):
        if self.path == "/validateResource":
            self.send_response(204)
            self.end_headers()
            return
        super().do_OPTIONS()

    def do_POST(self):
        if self.path != "/validateResource":
            self.send_error(404, "Not Found")
            return

        length = int(self.headers.get("Content-Length", "0"))
        payload = self.rfile.read(length)

        # 若有 X-Vad-IG 且該 IG 有對應後端，則轉發到該後端
        ig_id = self.headers.get("X-Vad-IG", "").strip()
        backend = _get_backend_for_ig(ig_id) if ig_id else None
        target_url = backend or BACKEND_URL

        request = urllib.request.Request(
            target_url, data=payload, method="POST"
        )
        if "Content-Type" in self.headers:
            request.add_header(
                "Content-Type", self.headers["Content-Type"]
            )
        if "Accept" in self.headers:
            request.add_header("Accept", self.headers["Accept"])

        try:
            with urllib.request.urlopen(request) as response:
                body = response.read()
                self.send_response(response.status)
                content_type = response.headers.get(
                    "Content-Type", "application/json"
                )
                self.send_header("Content-Type", content_type)
                self.end_headers()
                self.wfile.write(body)
        except urllib.error.HTTPError as error:
            body = error.read()
            self.send_response(error.code)
            content_type = error.headers.get(
                "Content-Type", "application/json"
            )
            self.send_header("Content-Type", content_type)
            self.end_headers()
            self.wfile.write(body)
        except Exception as error:
            self.send_response(502)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(str(error).encode("utf-8"))


def run_server(port=5500):
    server_address = ("", port)
    httpd = http.server.ThreadingHTTPServer(server_address, ProxyHandler)
    print(f"Serving on http://localhost:{port}")
    print(f"Proxying /validateResource -> {BACKEND_URL}")
    httpd.serve_forever()


if __name__ == "__main__":
    run_server()
