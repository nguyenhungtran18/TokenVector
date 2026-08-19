# -*- coding: utf-8 -*-
"""Kiem chung THAT http_get(url) (Wave 3, 2026-07-29, web/DB - xem
project-tokenvector-wave2-status memory) - anh xa System.Net.WebClient::
DownloadString(string), da xac minh THAT qua csc.exe truoc khi viet
(stdlib_http.py). Test dung mang THAT (khong mock) - CHI kiem tra do
dai > 0 (noi dung trang web co the doi theo thoi gian, do dai > 0 la
bang chung du HTTP GET that su chay va tra ve du lieu)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC_PATH = HERE / 'sample_http_get.tkv'
exe_path = HERE / 'sample_http_get_compute.exe'
compile_tkv_cli(SRC_PATH, exe_path, entry_name='get_len')

r = subprocess.run([str(exe_path), 'https://example.com'], capture_output=True, text=True)
if r.returncode != 0:
    print(f"exe THAT BAI (code {r.returncode})\nstdout: {r.stdout}\nstderr: {r.stderr}")
    sys.exit(1)
got = int(r.stdout.strip())
print(f"http_get('https://example.com') do dai: {got}")
if got <= 0:
    print("SAI LECH - do dai phai > 0 (HTTP GET that su thanh cong)")
    sys.exit(1)
print("HTTP_GET (System.Net.WebClient that): PASS - dung 100%.")
