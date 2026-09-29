# Smoke gate cho 2 repo KHAC: TokenVector.Inference va TokenVector.Data.
#
# LY DO CO (PLAN muc 1.1): co 1 lan, quy tac "chan field container tren
# record" pha 2 repo do, va CONG TESTKIT (chi phu `3.code/Testkit/`) KHONG
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
    [int]$TimeoutSec = 600
)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$tkv = Join-Path $root 'dist\tkvc.exe'
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
    Write-Output "SMOKE: ERROR - khong thay $tkv. Build lai bang build_tkvc.ps1 truoc."
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
    $msg = & $tkv build $t.Path --entry $t.Entry --out $exe --no-lint 2>&1 | Out-String
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
