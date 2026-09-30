# -*- coding: utf-8 -*-
# Chay doi chieu TokenVector voi CPython.
#
#   cd 3.code
#   python tools\parity_probe\run.ps1
#
# Hai file nguon `cmp_tkv.tkv` va `cmp_py.py` cung in ra cung mot danh sach
# NHAN, nen `diff.py` so dong mot mot. Khong sua tay: neu mot ben bao loi bien
# dich, chay lai va ghi vao `docs/SO_SANH_TOKENVECTOR_VS_PYTHON.md` muc "GACH".
#
# LUON Y: viet code bang Write/Edit tool. `Set-Content -Encoding utf8` cua
# PowerShell them BOM (U+FEFF) o dau file va compiler bao loi bien dich.
$ErrorActionPreference = 'Stop'
$probe = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $env:TEMP 'tkv_parity'
New-Item -ItemType Directory -Path $out -Force | Out-Null

python (Join-Path $probe 'cmp_py.py') > (Join-Path $out 'py.txt')
$tkvc = (Resolve-Path (Join-Path $PSScriptRoot '..\..\dist\tkvc.exe')).Path
& $tkvc build (Join-Path $probe 'cmp_tkv.tkv') `
    --out (Join-Path $out 'cmp_tkv.exe') --entry main --no-lint
if ($LASTEXITCODE -ne 0) { throw 'tkvc build that bai' }
& (Join-Path $out 'cmp_tkv.exe') > (Join-Path $out 'tv.txt')

python (Join-Path $probe 'diff.py') (Join-Path $out 'py.txt') (Join-Path $out 'tv.txt')
