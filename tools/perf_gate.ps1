# Gate HIEU NANG (2026-10-13).
#
# Ly do ton tai: lan sua `compile_binop` (chon khuon toi uu cho phep so
# nguyen) lam `f32mm` TUOT 10% MA GATE KHONG BAT - vi ca testkit_gate,
# dang_ky_gate, ext_smoke deu chi kiem tra TINH DUNG, khong ai do THOI
# GIAN. Day la "lai khong co dong ho".
#
# NGUYEN TAC:
#   1. KHONG so voi CPython/NumPy. Do da doi chieu roi va o repo khac.
#      Day doi chieu voi CHINH NO qua thoi gian: 39x nhanh hon hay 39x
#      cham di cung chua noi gi.
#   2. Neu exit code KHAC 0 -> dung ngay. Lai nhanh ma tinh RA SAI thi
#      te hon la cham - do la ky nguyen ban.
#   3. So sanh voi BASELINE. Chua co baseline -> ghi va cho qua (buoc
#      khoi tao mot lan). `-Update` de nap lai baseline sau khi da XEM
#      con so va DUNG Y doi thay doi la co chu dich.
#
# Cach dung:
#   .\tools\perf_gate.ps1              # do va so voi baseline
#   .\tools\perf_gate.ps1 -Update      # nap lai baseline
param(
    [double]$ThreshPct = 7.0,
    [switch]$Update,
    [int]$Runs = 5
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$here = Join-Path $PSScriptRoot "perf"
$TKVC = Join-Path $root "dist\tkvc-tv.exe"
$baseline = Join-Path $here "baseline.txt"
$tmp = Join-Path $env:TEMP "tkv_perf_gate"

if (-not (Test-Path -LiteralPath $TKVC)) {
    Write-Output "!! thieu $TKVC - khong the do"; exit 1
}
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$KERN = @()
Get-ChildItem -LiteralPath $here -Filter "*.tkv" | Where-Object { $_.Name -notmatch '^_' } | Sort-Object Name | ForEach-Object {
    $tag = $_.BaseName
    $KERN += $tag
    $exe = Join-Path $tmp "$tag.exe"
    & $TKVC $_.FullName $exe "main" | Out-Null
    if ((-not $?) -or -not (Test-Path -LiteralPath $exe)) {
        Write-Output "!! BUILD FAIL: $tag"; exit 1
    }
}

function Measure-One($exe) {
    $best = [double]::MaxValue
    $line = ""
    for ($i = 0; $i -lt $Runs; $i++) {
        # TUYET DOI khong pipe sang Select-Object: pipe cat mach se lam
        # process bi huy va exit code thanh khong 0 -> gate bao sai.
        $out = & $exe 2>&1
        if ($null -ne $out) { $line = ($out | Out-String).Trim() -split "`r?`n" | Select-Object -First 1 }
        if ($LASTEXITCODE -ne 0) { return @{ ms = -1; out = "" } }
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $out = & $exe 2>&1
        $sw.Stop()
        if ($LASTEXITCODE -ne 0) { return @{ ms = -1; out = "" } }
        if ($sw.Elapsed.TotalMilliseconds -lt $best) { $best = $sw.Elapsed.TotalMilliseconds }
    }
    return @{ ms = $best; out = $line }
}

# Do: lay (nhanh nhat) va (dong ket qua) rieng, de biet ket qua co on
# dinh khong khi do N lan.
$res = @{}
foreach ($kv in $KERN) {
    $r = Measure-One (Join-Path $tmp ($kv + ".exe"))
    if ($r.ms -lt 0) { Write-Output "!! RUN FAIL (exit != 0): $kv - doi chieu ket qua SAU KHI NHANH"; exit 1 }
    $res[$kv] = $r
    $tag = $kv.PadRight(14)
    Write-Output ("{0} {1,8:N1} ms   {2}" -f $tag, $r.ms, $r.out)
}

if ($Update -or -not (Test-Path -LiteralPath $baseline)) {
    $lines = @()
    foreach ($kv in $KERN) { $lines += ($kv + "`t" + $res[$kv].ms.ToString("F2")) }
    Set-Content -Path $baseline -Value $lines -Encoding UTF8
    Write-Output ""
    Write-Output "Da nap baseline: $baseline"
    if (-not (Test-Path -LiteralPath $baseline)) { exit 1 }
    exit 0
}

$base = @{}
Get-Content -LiteralPath $baseline | ForEach-Object {
    if ($_ -match "^(\S+)\s+([0-9.]+)") { $base[$Matches[1]] = [double]$Matches[2] }
}

$fail = 0
Write-Output ""
Write-Output ("{0,-14} {1,9} {2,9} {3,9}  {4}" -f "kernel", "hien tai", "baseline", "chenh", "trang thai")
Write-Output ("-" * 62)
foreach ($kv in $KERN) {
    $cur = $res[$kv].ms
    $old = $base[$kv]
    if ($null -eq $old) { Write-Output ("{0,-14} {1,9:N1} {2,9} {3,9}  CO BASELINE, bo qua" -f $kv, $cur, "-", "-"); continue }
    $pct = ($cur - $old) / $old * 100.0
    if ($pct -gt $ThreshPct) {
        $st = "TUOT {0:N1}%" -f $pct
        $fail = 1
    } elseif ($pct -lt -$ThreshPct) {
        $st = "nhanh hon {0:N1}%" -f (-$pct)
    } else {
        $st = "ok"
    }
    Write-Output ("{0,-14} {1,9:N1} {2,9:N1} {3,8:N1}%  {4}" -f $kv, $cur, $old, $pct, $st)
}

Write-Output ""
if ($fail) {
    Write-Output "GATE: FAIL - co kernel tuot qua $ThreshPct% so voi baseline."
    Write-Output "  Neu thay doi la CO CHU DICH (vd doi nguon, dat y) thi chay:"
    Write-Output "     .\tools\perf_gate.ps1 -Update"
    exit 1
}
Write-Output "GATE: PASS"
exit 0