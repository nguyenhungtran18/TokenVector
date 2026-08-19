# -*- coding: utf-8 -*-
"""http_request(): doc duoc STATUS CODE va HEADER TRA VE (2026-08-03).

WebClient (http_get/http_post) KHONG cho biet status code va NEM
WebException voi moi ma >= 400 - chuong trinh chet thay vi doc duoc
"404". Ham nay dung HttpWebRequest + bat WebException.

Server HTTP THAT chay cuc bo, tra ma trang thai KHAC NHAU theo duong dan
va gan 1 header rieng - bang chung den tu phia server."""
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
    def _go(self, code):
        n = int(self.headers.get('Content-Length') or 0)
        body = self.rfile.read(n).decode('utf-8') if n else ''
        payload = json.dumps({'m': self.command,
                              'ct': self.headers.get('Content-Type'),
                              'k': self.headers.get('X-Api-Key'),
                              'b': body}).encode('utf-8')
        self.send_response(code)
        self.send_header('X-Custom', 'hello')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._go(404 if self.path == '/missing' else 200)

    def do_POST(self):
        self._go(201)

    def log_message(self, *a):
        pass


srv = HTTPServer(('127.0.0.1', 0), EchoHandler)
threading.Thread(target=srv.serve_forever, daemon=True).start()
BASE = f'http://127.0.0.1:{srv.server_address[1]}'

SRC = HERE / 'sample_http_request.tkv'
CASES = [
    ('status_of', [BASE + '/ok'], '200'),
    # 404 KHONG duoc lam chuong trinh chet - day chinh la ly do ton tai
    # cua ham nay (WebClient nem WebException o day).
    ('status_of', [BASE + '/missing'], '404'),
    ('header_of', [BASE + '/ok', 'x-custom'], 'hello'),
]
mismatches = []
built = {}
for entry, args, expected in CASES:
    if entry not in built:
        exe_path = HERE / f'sample_hreq_{entry}.exe'
        if exe_path.exists():
            exe_path.unlink()
        compile_tkv_cli(SRC, exe_path, entry_name=entry)
        built[entry] = exe_path
    r = subprocess.run([str(built[entry]), *args], capture_output=True, text=True, timeout=60)
    got = r.stdout.strip()
    print(f'  {entry}({args[-1]}) -> {got!r} (ky vong {expected!r})')
    if r.returncode != 0 or got != expected:
        mismatches.append((entry, args, expected, got, r.returncode, r.stderr[:200]))

# body + POST: doi chieu voi chinh cai server nhan duoc
exe_body = HERE / 'sample_hreq_body_of.exe'
if exe_body.exists():
    exe_body.unlink()
compile_tkv_cli(SRC, exe_body, entry_name='body_of')
r = subprocess.run([str(exe_body), BASE + '/ok'], capture_output=True, text=True, timeout=60)
got_body = json.loads(r.stdout.strip())
if got_body['m'] != 'GET':
    mismatches.append(('body_of', 'GET', got_body))
else:
    print(f'  body_of -> server thay {got_body}')

exe_post = HERE / 'sample_hreq_post.exe'
if exe_post.exists():
    exe_post.unlink()
compile_tkv_cli(SRC, exe_post, entry_name='post_status_and_body')
r = subprocess.run([str(exe_post), BASE + '/p', '{"a":1}'], capture_output=True, text=True, timeout=60)
out = r.stdout.strip()
status, _, body_txt = out.partition('|')
srv.shutdown()
if status != '201':
    mismatches.append(('post status', '201', status))
else:
    seen = json.loads(body_txt)
    # Content-Type di qua property rieng cua HttpWebRequest, X-Api-Key qua
    # Headers.Set - kiem ca hai duong.
    if seen.get('ct') != 'application/json' or seen.get('k') != 'k1' or seen.get('b') != '{"a":1}':
        mismatches.append(('post echo', {'ct': 'application/json', 'k': 'k1', 'b': '{"a":1}'}, seen))
    else:
        print(f'  post_status_and_body -> 201 + server thay {seen}')

if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('http_request (status code + header tra ve, server THAT xac nhan): PASS - dung 100%.')
