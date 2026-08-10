# Build tkvc.exe - standalone TokenVector compiler.
#
# Cac file nguon trong package nay dung duoi `.tkv` (tkv.tkv, tkv_compile.tkv,
# tokenvector_compile.tkv, compiler/*.tkv) nhung NOI DUNG la Python that (xem
# docstring dau tkv_compile.tkv). Python import system KHONG tu nhan .tkv la
# module - "python tkv.tkv" bao loi ngay "ModuleNotFoundError: No module
# named 'tkv_compile'" vi no di tim tkv_compile.py, khong phai .tkv (da kiem
# chung truc tiep 2026-08-10). Nen truoc khi goi PyInstaller, script nay COPY
# tam moi file .tkv lien quan sang .py cung ten trong 1 thu muc staging rieng
# (KHONG sua file .tkv goc), roi build tu staging do.
#
# Chay: powershell -File build_tkvc.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$staging = Join-Path $root "build\pyinstaller_src"

if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path $staging | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $staging "compiler\il_features") | Out-Null

# Entry point + 2 module dung chung o cap goc.
Copy-Item (Join-Path $root "tkv.tkv")                 (Join-Path $staging "tkv.py")
Copy-Item (Join-Path $root "tkv_compile.tkv")          (Join-Path $staging "tkv_compile.py")
Copy-Item (Join-Path $root "tokenvector_compile.tkv")  (Join-Path $staging "tokenvector_compile.py")

# Toan bo compiler/*.tkv (kem il_features/*.tkv) -> .py, giu nguyen cay thu muc.
Get-ChildItem -Path (Join-Path $root "compiler") -Filter "*.tkv" -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring((Join-Path $root "compiler").Length + 1)
    $relPy = [System.IO.Path]::ChangeExtension($rel, ".py")
    $dest = Join-Path $staging "compiler\$relPy"
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item $_.FullName $dest
}

Push-Location $staging
try {
    python -m PyInstaller --onefile --name tkvc `
      --distpath (Join-Path $root "dist") `
      --workpath (Join-Path $root "build\pyinstaller") `
      --specpath (Join-Path $root "build") `
      --paths compiler `
      --collect-submodules il_features `
      tkv.py
} finally {
    Pop-Location
}

Write-Output "Da build: $(Join-Path $root 'dist\tkvc.exe')"
Write-Output "(Nguon staging tam thoi o $staging - co the xoa an toan, khong phai nguon that)"
