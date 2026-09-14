import hashlib
import html
import json
import mimetypes
import secrets
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


ASSETS = Path(__file__).resolve().parent / "pdf_preview"
PDFJS = ASSETS / "node_modules" / "pdfjs-dist"


def ensure_assets():
    if (PDFJS / "build" / "pdf.mjs").is_file():
        return
    print("Installing PDF preview dependencies…", file=sys.stderr, flush=True)
    subprocess.run(
        [
            "npm", "ci", "--omit=dev", "--omit=optional",
            "--ignore-scripts", "--no-audit", "--no-fund",
        ],
        cwd=ASSETS,
        stdout=sys.stderr,
        check=True,
    )


class Preview:
    def __init__(self, path):
        self.path = path
        self.snapshot = (b"", "")
        self.refresh()

    def refresh(self):
        data = self.path.read_bytes()
        if not data.startswith(b"%PDF-") or b"%%EOF" not in data[-1024:]:
            raise ValueError("PDF is incomplete")
        self.snapshot = (data, hashlib.sha256(data).hexdigest())


def create_server(preview):
    prefix = "/" + secrets.token_urlsafe(24) + "/"

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlsplit(self.path).path
            data, version = preview.snapshot
            if path == prefix:
                body = (ASSETS / "index.html").read_text().replace(
                    "{{title}}", html.escape(preview.path.name)
                ).encode()
                content_type = "text/html; charset=utf-8"
            elif path == prefix + "version":
                body = json.dumps(version).encode()
                content_type = "application/json"
            elif path == prefix + "document.pdf":
                body = data
                content_type = "application/pdf"
            elif path in (prefix + "viewer.mjs", prefix + "viewer.css"):
                asset = ASSETS / path.removeprefix(prefix)
                body = asset.read_bytes()
                content_type = "text/javascript" if asset.suffix == ".mjs" else "text/css"
            elif path.startswith(prefix + "pdfjs/"):
                asset = (PDFJS / path.removeprefix(prefix + "pdfjs/")).resolve()
                if not asset.is_relative_to(PDFJS.resolve()) or not asset.is_file():
                    self.send_error(404)
                    return
                body = asset.read_bytes()
                content_type = (
                    "text/javascript" if asset.suffix == ".mjs"
                    else mimetypes.guess_type(asset)[0] or "application/octet-stream"
                )
            else:
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header(
                "Cache-Control",
                "private, max-age=86400" if path.startswith(prefix + "pdfjs/") else "no-store",
            )
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    return server, f"http://127.0.0.1:{server.server_port}{prefix}"


def main():
    ensure_assets()
    preview = Preview(Path(sys.argv[1]))
    server, url = create_server(preview)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print(url, flush=True)
    try:
        for line in sys.stdin:
            if line.strip() == "refresh":
                try:
                    preview.refresh()
                except (OSError, ValueError) as error:
                    print(f"PDF preview: {error}", file=sys.stderr, flush=True)
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
