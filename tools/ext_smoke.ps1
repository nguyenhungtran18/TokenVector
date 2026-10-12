# Smoke gate cho 2 repo KHAC: TokenVector.Inference va TokenVector.Data.
#
# LY DO CO (PLAN muc 1.1): co 1 lan, quy tac "chan field container tren
# record" pha 2 repo do, va CONG TESTKIT (chi phu `tests/`) KHONG
# bat duoc - phai het 15 commit moi phat hien, va bang so "26/26" stale
# trong PLAN. Cong nay build thi MOT PHAN nho (khong chay het suite) de
# hoi compiler "2 repo do con build duoc khong", nhanh hon nhieu.
#
# CHAY:
#   powershell -File .\tools\ext_smoke.ps1
#   powershell -File .\tools\ext_smoke.ps1 -UpdateBaseline   # cap nhat ky vong
#
# TINH TRANG: neu 2 repo khong ton tai (clone moi chi co 3.code) -> SKIP,
# KHONG phai fail. Exit != 0 CHI khi co REGRESSION: mot muc da tung BUILD_OK
# roi gio fail. Muc dang fail ma thay doi thong diep thi bao CHANGED de nguoi
# doc biet - co the la ca khac (nho la thay doi can thiet) hoac bug moi
# (cau hoi, xem ky vong).
param(
    [switch]$UpdateBaseline,
    [int]$TimeoutSec = 600,
    # 2026-10-12: them tham so Compiler. Truoc day khong co, nen truyen
    # `-Compiler ...` vo mot script phai [CmdletBinding] se bi BO QUA im
    # lang - va ta tu kiem cong do `-Compiler .\dist\tkvc-tv.exe` xanh 4/4
    # trong khi thuc te van dung compiler mac dinh. Phai khai bao tham so
    # that moi cho phep doi compiler co chu dich.
    [string]$Compiler = ''
)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
# 2026-10-12: mac dinh GIU NGUYEN compiler Python bootstrap (`dist\tkvc.exe`).
# Da thu chuyen sang `tkvc-tv.exe` va gate FAIL 4/4 - KHONG phai vi self-host
# hong, ma vi no CHUA build duoc 2 project ben ngoai:
#   il_codegen: d.shape[0] khong hop le (shape=[])   tren inference_tests.tkv
# Python bootstrap build duoc ca 4. Day la HUU ICH THAT cua gate nay (so sanh
# kha nang cua hai compiler), nen mac dinh phai la compiler manh hon.
# Con cau hoi "compiler TU-HOST co build duoc 2 project ngoai khong" thi day
# CHINH la regression can bao cao, khong phai trang thai binh thuong.
#
# CLI hai compiler khac nhau (`build <src> --out <e>` co subcommand,
# tkvc-tv.exe chi nhan positional `<src> <out> <entry>`) - xem nhanh goi
# ben duoi.
if ([string]::IsNullOrEmpty($Compiler)) { $tkv = Join-Path $root 'dist\tkvc.exe' }
else { $tkv = $Compiler }
$tuHost = ($tkv -like '*tkvc-tv.exe')
$baselinePath = Join-Path $PSScriptRoot 'ext_smoke_baseline.txt'
$outDir = Join-Path $env:TEMP 'ext_smoke'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Muc: "duong dan|entry". Chi BUILD, khong chay (datagate.ps1 chay mat ~5 phut).
$targets = @(
    @{ Name = 'inference'; Path = 'D:\TokenVector.Inference\tv\tests\inference_tests.tkv'; Entry = 'main' },
    @{ Name = 'data_lib';  Path = 'D:\TokenVector.Data\tvsrc\_libbuild.tkv'; Entry = 'dt_name' },
    @{ Name = 'data_core'; Path = 'D:\TokenVector.Data\tvsrc\core_check.tkv'; Entry = 'dt_name' },
    @{ Name = 'data_arr';  Path = 'D:\TokenVector.Data\tvsrc\arr_check.tkv'; Entry = 'dt_name' }
)

if (-not (Test-Path $tkv)) {
    Write-Output "SMOKE: ERROR - khong thay $tkv. Build lai bang .\compiler_py\build_tkvc.ps1 -DistDir .\dist -BuildDir .\build truoc."
    exit 2
}

# Chu ky vong: "<ten> = BUILD_OK" hoac "<ten> = KNOWN_FAIL:<chuoi thong diep>",
# dau thong diep la phan DAI NHA phat hien loi `[tkv] Loi:`.
$expected = @{}
if (Test-Path $baselinePath) {
    foreach ($line in Get-Content $baselinePath) {
        if ($line -match '^\s*([a-z_]+)\s*=\s*(.+?)\s*$') { $expected[$Matches[1]] = $Matches[2] }
    }
}

function Get-NormalizedError([string]$msg) {
    $line = ($msg -split "`n" | Where-Object { $_ -match 'Loi' } | Select-Object -First 1)
    if (-not $line) { $line = ($msg -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1) }
    $text = ($line -replace '.*Loi:\s*', '').Trim() -replace '\s+', ' '
    if ($text.Length -gt 70) { $text = $text.Substring(0, 70) }
    return $text
}

$regression = 0
$changed = 0
$ok = 0
$skip = 0
$observed = @{}

foreach ($t in $targets) {
    if (-not (Test-Path $t.Path)) {
        Write-Output ("  skip  {0,-11} (khong co {1})" -f $t.Name, $t.Path)
        $skip++
        continue
    }
    $exe = Join-Path $outDir ("{0}.exe" -f $t.Name)
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    # Hai CLI khac nhau - tkvc.exe co subcommand `build` va co `--out`,
    # tkvc-tv.exe chi nhan positional `<src> <out> <entry>` va khong co
    # co `--no-lint`.
    if ($tuHost) {
        $msg = & $tkv $t.Path $exe $t.Entry 2>&1 | Out-String
    } else {
        $msg = & $tkv build $t.Path --entry $t.Entry --out $exe --no-lint 2>&1 | Out-String
    }
    $actual = if (Test-Path $exe) { 'BUILD_OK' } else { 'KNOWN_FAIL:' + (Get-NormalizedError $msg) }
    $observed[$t.Name] = $actual
    $want = if ($expected.ContainsKey($t.Name)) { $expected[$t.Name] } else { '<chua co ky vong>' }
    if ($actual -eq 'BUILD_OK' -and $want -eq 'BUILD_OK') {
        Write-Output ("  ok    {0,-11} BUILD OK" -f $t.Name); $ok++
    } elseif ($actual -eq 'BUILD_OK') {
        Write-Output ("  ok+   {0,-11} BUILD OK (truoc do: {1}) - DA KHUOC PHUC" -f $t.Name, $want)
        $ok++
    } elseif ($want -eq 'BUILD_OK') {
        Write-Output ("  REGR  {0,-11} truoc do BUILD OK, gio: {1}" -f $t.Name, $actual)
        $regression++
    } elseif ($want -eq $actual) {
        Write-Output ("  ok    {0,-11} van fail bang loi da biet" -f $t.Name); $ok++
    } else {
        Write-Output ("  CHANGE {0,-11} loi doi:" -f $t.Name)
        Write-Output ("         ky vong: {0}" -f $want)
        Write-Output ("         thuc te : {0}" -f $actual)
        $changed++
    }
}

if ($UpdateBaseline) {
    $lines = foreach ($name in ($targets | ForEach-Object { $_.Name })) {
        if ($observed.ContainsKey($name)) { "$name = $($observed[$name])" }
    }
    Set-Content -Path $baselinePath -Value $lines -Encoding utf8
    Write-Output ""
    Write-Output "SMOKE: da cap nhat ky vong trong $baselinePath"
}

Write-Output ""
Write-Output ("SMOKE: ok={0} changed={1} regression={2} skip={3}" -f $ok, $changed, $regression, $skip)
if ($regression -gt 0) {
    Write-Output "SMOKE: FAIL (co regression)"
    exit 1
}
Write-Output "SMOKE: PASS"
exit 0
