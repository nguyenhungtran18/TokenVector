# -*- coding: utf-8 -*-
"""Header TUY Y (dict[str,str]) cho HTTP - Giai doan 3 bo sung, 2026-08-03.

Truoc do chi set duoc Content-Type, nen 'Authorization: Bearer <token>'
- thu gan nhu MOI API that doi hoi - la khong the. Test dung 1 HTTP
server THAT chay cuc bo, ECHO lai chinh cac header no NHAN DUOC: bang
chung den tu phia server."""
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
        payload = json.dumps({
            'method': self.command,
            'body': body,
            'headers': {k.lower(): v for k, v in self.headers.items()},
        }, ensure_ascii=False).encode('utf-8')
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
TOKEN = 'tok-xyz-123'

SRC = HERE / 'sample_http_headers.tkv'
CASES = [
    ('post_with_auth', [URL, TOKEN], 'POST',
     {'authorization': f'Bearer {TOKEN}', 'x-api-key': 'abc123',
      'content-type': 'application/json'}, '{"a":1}'),
    ('get_with_auth', [URL, TOKEN], 'GET', {'authorization': f'Bearer {TOKEN}'}, ''),
    # dict GHI DE Content-Type mac dinh (application/json -> text/xml)
    ('put_override_ctype', [URL], 'PUT',
     {'content-type': 'text/xml', 'x-trace': 't-1'}, '<x>1</x>'),
    ('delete_with_header', [URL], 'DELETE', {'x-reason': 'cleanup'}, ''),
    # User-Agent la header "han che" trong HttpWebRequest (dat sai cach se
    # nem ArgumentException) - qua WebClient.Headers thi dat duoc: kiem
    # chung THAT o day thay vi doan.
    ('get_with_user_agent', [URL], 'GET',
     {'user-agent': 'TokenVector/1.0', 'accept': 'application/json'}, ''),
]

mismatches = []
for entry, args, method, want_headers, want_body in CASES:
    exe_path = HERE / f'sample_httph_{entry}.exe'
    if exe_path.exists():
        exe_path.unlink()
    compile_tkv_cli(SRC, exe_path, entry_name=entry)
    r = subprocess.run([str(exe_path), *args], capture_output=True, text=True, timeout=60)
    try:
        got = json.loads(r.stdout.strip())
    except Exception:
        mismatches.append((entry, 'JSON tu server', r.stdout.strip(), r.stderr[:200]))
        print(f'  FAIL {entry}: {r.stdout.strip()!r} {r.stderr[:200]}')
        continue
    bad = {}
    if got.get('method') != method:
        bad['method'] = (method, got.get('method'))
    if got.get('body') != want_body:
        bad['body'] = (want_body, got.get('body'))
    for k, v in want_headers.items():
        if got['headers'].get(k) != v:
            bad[k] = (v, got['headers'].get(k))
    if bad:
        mismatches.append((entry, bad))
        print(f'  FAIL {entry}: {bad}')
    else:
        shown = {k: got['headers'].get(k) for k in want_headers}
        print(f'  PASS {entry}: server nhan {method} {shown} body={got["body"]!r}')

srv.shutdown()
if mismatches:
    print('SAI LECH:')
    for m in mismatches:
        print(' ', m)
    sys.exit(1)
print('Header tuy y qua dict[str,str] (server THAT xac nhan): PASS - dung 100%.')
