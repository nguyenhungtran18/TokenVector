# Cong cho lexer TokenVector (phan compiler viet bang TokenVector THAT).
#
# Chay: powershell -NoProfile -File tools\compiler_tkv\run.ps1
#
# Kiem 2 thu:
#   1. Cau noi: compiler Python chay duoc lexer TokenVector da bien dich.
#   2. Do chinh xac: token lexer sinh ra khop 100% voi CPython tren nguon
#      TokenVector that. File PYTHON (tkv.tkv, tkv_compile.tkv...) phai KHAC -
#      chung dung nhay don ma TokenVector khong co, va su lech do la bang chung
#      cho thay lexer phan biet duoc hai ngon ngu.
#
# NO nen co gate rieng: mot quy tac lexer ma khong co test la quy tac chua
# viet. Da gap 3 lan trong luc lam - moi lan deu do la loi cua HARNESS, khong
# phai cua lexer (xem README.md muc "3 sai lam cua toi").

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$here = $PSScriptRoot
$env:PYTHONIOENCODING = 'utf-8'

Write-Host "=== compiler_tkv: cau noi ==="
& python (Join-Path $here 'probe_bridge.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] cau noi hong" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== compiler_tkv: do chinh xac tren file that ==="
& python (Join-Path $here 'probe_many_files.py')
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] lexer chua khop CPython tren nguon TokenVector" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "PASS: lexer TokenVector khop CPython 100% tren nguon TokenVector that"
exit 0
