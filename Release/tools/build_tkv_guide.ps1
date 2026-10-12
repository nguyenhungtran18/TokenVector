# Build dist\bin\tkv_guide.exe tu tools\tkv_guide.tkv.
#
# Chay: powershell -NoProfile -File tools\build_tkv_guide.ps1
#
# Tool nay viet bang TokenVector nen can chinh compiler bien dich no.
# Mac dinh dung COMPILER TU-HOST (`dist\tkvc-tv.exe`) nen script chay duoc
# ma khong can Python. Doi sang compiler Python bootstrap (`tkvc.exe`) thi
# CLI khac nhau: `tkvc.exe build <src> --out <exe> --entry run` co subcommand
# `build` va co `--out`, con tkvc-tv.exe chi nhan positional
# `<src> <out> <entry>`. Script tu do dap - xem nhanh ben duoi.
#
# `dist/` trong .gitignore nen file `.tkv` o tools/ la ban nguon duy nhat
# can commit.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'tools\tkv_guide.tkv'
$outDir = Join-Path $root 'dist\bin'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
$out = Join-Path $outDir 'tkv_guide.exe'
$comp = Join-Path $root 'dist\tkvc-tv.exe'
if (-not (Test-Path $comp)) { $comp = Join-Path $root 'dist\tkvc.exe' }

if (-not (Test-Path $comp)) {
    Write-Error "THIEU compiler: $comp`nBuild truoc: dist\tkvc-tv.exe (compiler tu-host)"
    exit 2
}
if (Test-Path $out) { Remove-Item $out -Force }

$tuHost = ($comp -like '*tkvc-tv.exe')
if ($tuHost) {
    & $comp $src $out run
} else {
    & $comp build $src --out $out --entry run
}
if ($LASTEXITCODE -ne 0) {
    Write-Error "tkv_guide build THAT BAI (exit $LASTEXITCODE)"
    exit 1
}
if (-not (Test-Path $out)) {
    Write-Error "Khong tao duoc $out"
    exit 1
}
# tkvc LUON ghi them mot `<out>.il` canh ben exe (khong chi khi --emit-il).
# `dist/` la thu muc ket qua nen file do phai bi xoa, neu khong no se ton tai
# va lai lan sau. (Gitignore `*.il` van la luoi an toan.)
$il = [System.IO.Path]::ChangeExtension($out, '.il')
if (Test-Path $il) { Remove-Item $il -Force }

Write-Host "OK: $out"
& $out rules --file (Join-Path $env:TEMP 'tkv_guide_rules_selftest.txt')
exit 0

