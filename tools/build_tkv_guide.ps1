# Build dist\tkv_guide.exe tu tools\tkv_guide.tkv.
#
# Chay: powershell -NoProfile -File tools\build_tkv_guide.ps1
#
# Tool nay viet bang TokenVector nen can chinh tkvc.exe bien dich no - dung
# tai compiler, khong can Python. `dist/` trong .gitignore nen file `.tkv` o
# tools/ la ban nguon duy nhat can commit.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'tools\tkv_guide.tkv'
$out = Join-Path $root 'dist\tkv_guide.exe'
$comp = Join-Path $root 'dist\tkvc.exe'

if (-not (Test-Path $comp)) {
    Write-Error "THIEU compiler: $comp`nBuild truoc: powershell -File build_tkvc.ps1"
    exit 2
}
if (Test-Path $out) { Remove-Item $out -Force }

& $comp build $src --out $out --entry run
if ($LASTEXITCODE -ne 0) {
    Write-Error "tkv_guide build THAT BAI (exit $LASTEXITCODE)"
    exit 1
}
if (-not (Test-Path $out)) {
    Write-Error "Khong tao duoc $out"
    exit 1
}
Write-Host "OK: $out"
& $out rules --file (Join-Path $env:TEMP 'tkv_guide_rules_selftest.txt')
exit 0
