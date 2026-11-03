# Gate HIEU NANG (2026-10-13).
#
# Ly do ton tai: lan sua `compile_binop` (chon khuon toi uu cho phep so
# nguyen) lam `f32mm` TUOT 10% MA GATE KHONG BAT - vi ca testkit_gate va
# dang_ky_gate deu chi kiem tra TINH DUNG, khong ai do THOI GIAN. Day la
# "lai khong co dong ho".
#
# NGUYEN TAC:
#   1. KHONG so voi CPython/NumPy. Do da doi chieu roi va o repo khac.
#      Day doi chieu voi CHINH NO qua thoi gian: 39x nhanh hon hay 39x
#      cham di cung chua noi gi.
#   2. Neu exit code KHAC 0 -> dung ngay. Lai nhanh ma tinh RA SAI thi
#      te hon la cham - do la ky nguyen ban. => checksum (dong `print` dau
#      tien cua moi kernel) LUON duoc SO voi baseline. Baseline cu (truoc
#      2026-10-14) chi luu ms - THIEU checksum nen khi gap duong 2 cot
#      (khong co checksum) gate chi can canh bao, khong fail.
#   3. So sanh voi BASELINE. Chua co baseline -> ghi va cho qua (buoc
#      khoi tao mot lan). `-Update` de nap lai baseline sau khi da XEM
#      con so va DUNG Y doi thay doi la co chu dich.
#
# Cach dung:
#   .\tools\perf_gate.ps1              # do va so voi baseline
#   .\tools\perf_gate.ps1 -Update      # nap lai baseline
#
# RUNTIME (2026-10-30): kernel `perf_e2e` (va bat ky kernel nao sinh boi
# codegen f64 `Vector<double>` + `Widen/Narrow`) KHONG chay tren .NET
# Framework - `System.Numerics.Vector\u00601` / `Widen` khong co o do ->
# `TypeLoadException`/`MissingMethodException` NGAY luc `& $exe`. Nen toan
# bo gate chay bang `dotnet exec --runtimeconfig` tren .NET 10 (runtime co
# `Widen`/`Narrow` hardware) - cung chien luoc voi `tools/gate_f32.sh`.
# HOP DONG: moi binary sinh boi codegen f64 chi chay tren .NET 10 (HANDOFF
# 0.56.1). Vi runtime doi, ms baseline cu (do tren .NET Framework) khong
# con doi chieu duoc - phai chay `-Update` MOT LAN sau khi da xem so, rieng
# CHECKSUM van so duoc voi baseline cu (so khong phu thuoc runtime - da kiem).
param(
    [double]$ThreshPct = 7.0,
    [switch]$Update,
    # 2026-10-30: 5 -> 15. Do la TOAN BO process nen min cua 5 lan van con
    # nhieu jitter ~chuc % o kernel nho (~16 ms net). Lay min nhieu hon thi
    # gan day du toi thieu (khoi dong + code) - on hon nhieu hon 5 lan.
    [int]$Runs = 15
)
# Nguong NHIEU TOAN TUYET (ms). Moi lan do la mot process moi, nen net
# (tong - tare) van con jitter ~1.5-2 ms do trinh doi/va CPU - lon hon 7%
# cua mot so kernel nho (perf_f32mm net ~20 ms -> 7% = 1.4 ms). Khong co
# cai nay thi gate FLAP: do dung cong ngay cung van TUOT va nguoi chay se
# quen chay `-Update` = mat canh bao. Chi FAIL khi DONG THOI vuot 7% VA
# vuot khoi do nhieu -> kernel lon (delta hang chuc ms) van bat binh thuong.
$NoiseMs = 2.5
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

# --- runtime .NET 10 cho `dotnet exec` (xem ghi chu tren) --------------------
$rtVer = $null
try {
    $rtVer = (& dotnet --list-runtimes 2>$null |
        Where-Object { $_ -match '^Microsoft\.NETCore\.App ' } |
        ForEach-Object { if ($_ -match '([0-9]+\.[0-9]+\.[0-9]+)') { $Matches[1] } } |
        Select-Object -Last 1)
} catch { $rtVer = $null }
$rtCfg = Join-Path $tmp "perf_gate.runtimeconfig.json"
if ($rtVer) {
    @"
{
  "runtimeOptions": {
    "tfm": "net10.0",
    "framework": { "name": "Microsoft.NETCore.App", "version": "$rtVer" }
  }
}
"@ | Set-Content -Path $rtCfg -Encoding ASCII
} else {
    Write-Output "!! khong tim thay .NET runtime - perf_gate can no (codegen f64)"
    exit 1
}

# Chay 1 kernel. Tra ve @{ ec = <exit code>; out = <stdout> }.
function Invoke-PerfExe([string]$exe) {
    $out = & dotnet exec --runtimeconfig $rtCfg $exe 2>&1
    return @{ ec = $LASTEXITCODE; out = ($out | Out-String) }
}

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
        $r0 = Invoke-PerfExe $exe
        if ($null -ne $r0.out) { $line = $r0.out.Trim() -split "`r?`n" | Select-Object -First 1 }
        if ($r0.ec -ne 0) { return @{ ms = -1; out = "" } }
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r1 = Invoke-PerfExe $exe
        $sw.Stop()
        if ($r1.ec -ne 0) { return @{ ms = -1; out = "" } }
        if ($sw.Elapsed.TotalMilliseconds -lt $best) { $best = $sw.Elapsed.TotalMilliseconds }
    }
    return @{ ms = $best; out = $line }
}

# --- TARE: tru khoi dong runtime khoi TUNG kernel ---------------------------
# Ly do: `Measure-One` do ca process, va .NET 10 startup van cham hon .NET
# Framework cu -> neu khong tru thi 7% se do "khoi dong" thay vi do code.
# `_tare.tkv` (ten bat dau `_` nen bi bo qua khi liet ke kernel) la mot main
# rong - so do duoc la chi phi khoi dong thuan. `net = tong - tare`.
$TARE_EXE = Join-Path $tmp "_tare.exe"
& $TKVC (Join-Path $here "_tare.tkv") $TARE_EXE "main" | Out-Null
if (-not (Test-Path -LiteralPath $TARE_EXE)) {
    Write-Output "!! BUILD FAIL: _tare (khong tru duoc khoi dong runtime)"; exit 1
}
$tareMs = (Measure-One $TARE_EXE).ms
if ($tareMs -lt 0) { Write-Output "!! RUN FAIL: _tare"; exit 1 }
Write-Output ("tare (khoi dong .NET 10) = {0:N1} ms`n" -f $tareMs)

# Do: lay (nhanh nhat) va (dong ket qua) rieng, de biet ket qua co on
# dinh khong khi do N lan.
$res = @{}
foreach ($kv in $KERN) {
    $r = Measure-One (Join-Path $tmp ($kv + ".exe"))
    if ($r.ms -lt 0) { Write-Output "!! RUN FAIL (exit != 0): $kv - doi chieu ket qua SAU KHI NHANH"; exit 1 }
    # net = tong - tare (xem ghi chu tren). `out` giuyen - do la checksum.
    $r = @{ ms = [Math]::Max($r.ms - $tareMs, 0.0); out = $r.out }
    $res[$kv] = $r
    $tag = $kv.PadRight(14)
    Write-Output ("{0} {1,8:N1} ms   {2}" -f $tag, $r.ms, $r.out)
}

if ($Update -or -not (Test-Path -LiteralPath $baseline)) {
    $lines = @()
    foreach ($kv in $KERN) {
        # 3 COT: ten, ms, checksum. Checksum de o CUOI va thay TAB bang
        # ' ' de no khong lam vo duong phan tich (va de doc duoc bang notepad).
        $cs = ($res[$kv].out -replace "`t", " ")
        $lines += ($kv + "`t" + $res[$kv].ms.ToString("F2") + "`t" + $cs)
    }
    Set-Content -Path $baseline -Value $lines -Encoding UTF8
    Write-Output ""
    Write-Output "Da nap baseline: $baseline"
    if (-not (Test-Path -LiteralPath $baseline)) { exit 1 }
    exit 0
}

$base = @{}
$base_cs = @{}
Get-Content -LiteralPath $baseline | ForEach-Object {
    # 3 COT: ten / ms / checksum. Baseline 2 COT (truoc 2026-10-14) van
    # doc duoc - chi khong co checksum de so.
    if ($_ -match "^(\S+)\s+([0-9.]+)\s*(.*)$") {
        $base[$Matches[1]] = [double]$Matches[2]
        $cs = $Matches[3].Trim()
        if ($cs -ne '') { $base_cs[$Matches[1]] = $cs }
    }
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
    # CHECKSUM TRUOC, THOI GIAN SAU. Mot kernel tinh ra SAI ma nhanh hon
    # thi phai FAIL - nhanh sai thi te hon cham sai (nguyen lan muc 2).
    $cs_now = ($res[$kv].out -replace "`t", " ").Trim()
    $cs_old = $base_cs[$kv]
    if ($null -eq $cs_old) {
        $st = "ok (baseline chua co checksum)"
    } elseif ($cs_now -ne $cs_old) {
        Write-Output ("{0,-14} {1,9:N1} {2,9:N1} {3,8:N1}%  CHECKSUM LECH" -f $kv, $cur, $old, $pct)
        Write-Output ("    hien tai : " + $cs_now)
        Write-Output ("    baseline : " + $cs_old)
        $fail = 1
        continue
    }
    if ($null -ne $cs_old) {
        $delta = $cur - $old
        if ($pct -gt $ThreshPct -and $delta -gt $NoiseMs) {
            $st = "TUOT {0:N1}%" -f $pct
            $fail = 1
        } elseif ($pct -lt -$ThreshPct) {
            $st = "nhanh hon {0:N1}%" -f (-$pct)
        } else {
            $st = "ok"
        }
    }
    Write-Output ("{0,-14} {1,9:N1} {2,9:N1} {3,8:N1}%  {4}" -f $kv, $cur, $old, $pct, $st)
}

Write-Output ""
if ($fail) {
    Write-Output "GATE: FAIL - xem bang o tren: 'TUOT' la cham lai, 'CHECKSUM LECH' la tinh sai."
    Write-Output "  Neu thay doi la CO CHU DICH (vd doi nguon, dat y) thi chay:"
    Write-Output "     .\tools\perf_gate.ps1 -Update"
    exit 1
}
Write-Output "GATE: PASS"
exit 0