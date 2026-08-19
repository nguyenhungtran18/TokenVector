# -*- coding: utf-8 -*-
"""HTTP POST/PUT/DELETE + Content-Type tu chon (Giai doan 3, 2026-08-03).

Server HTTP THAT chay cuc bo (http.server cua Python) ECHO lai method +
Content-Type + body ma no NHAN DUOC. Nho vay bang chung den tu PHIA
SERVER: khong phai "exe khong crash" ma la "server nhan dung dong tu HTTP,
dung Content-Type, dung noi dung"."""
import json
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent


class EchoHandler(BaseHTTPRequestHandler):
    def _echo(self):
        n = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(n).decode('utf-8') if n else ''
        payload = json.dumps({'method': self.command,
                              'ctype': self.headers.get('Content-Type') or '',
                              'body': body}, ensure_ascii=False).encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    do_POST = do_PUT = do_DELETE = do_GET = _echo

    def log_message(self, *a):
        pass


srv = HTTPServer(('127.0.0.1', 0), EchoHandler)
port = srv.server_address[1]
threading.Thread(target=srv.serve_forever, daemon=True).start()
URL = f'http://127.0.0.1:{port}/api'

SRC = HERE / 'sample_http_verbs.tkv'
mismatches = []
CASES = [
    ('do_post', [URL, '{"a":1}'], {'method': 'POST', 'ctype': 'application/json', 'body': '{"a":1}'}),
    ('do_post_type', [URL, 'a=1&b=2', 'application/x-www-form-urlencoded'],
     {'method': 'POST', 'ctype': 'application/x-www-form-urlencoded', 'body': 'a=1&b=2'}),
    ('do_put', [URL, '<x>1</x>', 'text/xml'],
     {'method': 'PUT', 'ctype': 'text/xml', 'body': '<x>1</x>'}),
    ('do_delete', [URL], {'method': 'DELETE', 'body': ''}),
]
for entry, args, expected in CASES:
    exe_path = HERE / f'sample_http_{entry}.exe'
    if exe_path.exists():
        exe_path.unlink()
    compile_tkv_cli(SRC, exe_path, entry_name=entry)
    r = subprocess.run([str(exe_path), *args], capture_output=True, text=True, timeout=60)
    try:
        got = json.loads(r.stdout.strip())
    except Exception:
        mismatches.append((entry, expected, r.stdout.strip(), r.stderr[:200]))
        print(f'  FAIL {entry}: stdout khong phai JSON: {r.stdout.strip()!r} {r.stderr[:200]}')
        continue
    diff = {k: (v, got.get(k)) for k, v in expected.items() if got.get(k) != v}
    if diff:
        mismatches.append((entry, diff))
        print(f'  FAIL {entry}: {diff}')
    else:
        print(f'  PASS {entry}: server nhan {got}')

srv.shutdown()
if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('HTTP POST/PUT/DELETE + Content-Type (server THAT xac nhan): PASS - dung 100%.')
