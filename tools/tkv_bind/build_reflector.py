# -*- coding: utf-8 -*-
"""Bien dich reflector.cs thanh reflector.exe qua csc.exe (cache: chi
bien dich lai neu noi dung .cs thay doi so voi lan build truoc, hoac
.exe chua ton tai).

LICH SU BUG (Phase 9d Part A, Task 5 review finding): ban cu dung
mtime(.cs) > mtime(.exe) de quyet dinh rebuild. `git checkout` gan
mtime GIONG NHAU cho moi file duoc checkout ra, nen sau 1 lan checkout
moi, dieu kien ">" la FALSE va reflector.exe cu (stale) bi tai su dung
am tham du reflector.cs da doi noi dung tu lau - da xay ra that trong
Phase 9d Part A, gay sai so lieu do (405 thay vi 447 lop). Fix: so
sanh hash noi dung .cs voi hash da luu tu lan build truoc (luu trong
file .hash canh .exe), khong con phu thuoc mtime nua."""
import hashlib
import os
import subprocess

from find_csc import find_csc

_HERE = os.path.dirname(os.path.abspath(__file__))
_CS_PATH = os.path.join(_HERE, "reflector.cs")
_EXE_PATH = os.path.join(_HERE, "reflector.exe")
_HASH_PATH = os.path.join(_HERE, "reflector.exe.srchash")

# I1 (final review Phase 9d Part A, 2026-08-26): reflector.exe/.srchash KHONG
# duoc git-track (xem .gitignore) - luon rebuild-on-demand tu reflector.cs
# qua ham nay (hash-cache o duoi tranh rebuild thua), nen KHONG bao gio co
# nguy co .exe da commit lech voi .cs nguon (dung 1 tang cao hon bug mtime
# da sua o duoi).


def _source_hash():
    with open(_CS_PATH, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def _stored_hash():
    if not os.path.isfile(_HASH_PATH):
        return None
    with open(_HASH_PATH, "r", encoding="utf-8") as f:
        return f.read().strip()


def build_reflector():
    current_hash = _source_hash()
    needs_build = (
        not os.path.isfile(_EXE_PATH)
        or current_hash != _stored_hash()
    )
    if needs_build:
        csc = find_csc()
        # /platform:x86: buoc reflector.exe chay 32-bit de tranh
        # BadImageFormatException khi Assembly.LoadFrom() nap 1 DLL cung
        # bitness voi CLR host (vd mscorlib.dll ban Framework\ 32-bit
        # khac file voi ban Framework64\). GIOI HAN DA BIET: reflector.exe
        # ban x86 nay se KHONG mo duoc assembly x64-only/mixed-mode -
        # da xac nhan trade-off nay chap nhan duoc cho MVP vi da so thu
        # vien .NET dung de bind la pure-IL/AnyCPU (nap duoc o ca 2 bitness).
        result = subprocess.run(
            [csc, "/nologo", "/target:exe", "/platform:x86", "/out:" + _EXE_PATH, _CS_PATH],
            capture_output=True, text=True, timeout=120)
        if result.returncode != 0:
            raise RuntimeError(
                "[tkv-bind] csc.exe bien dich reflector.cs that bai:\n"
                + result.stdout + result.stderr)
        with open(_HASH_PATH, "w", encoding="utf-8") as f:
            f.write(current_hash)
    return _EXE_PATH
