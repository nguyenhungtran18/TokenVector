<#
.SYNOPSIS
  Khang dinh IL sinh ra - GATE 7.

.DESCRIPTION
  Test runtime KHONG bat duoc IL sai. ilasm khong kiem tra kieu toan hang;
  CLR jit 'va chay, doc nham 4 byte con tro object thanh so, va ket qua
  van dung - do chinh xac la loi `conv.i8` tren con tro List<int32> ma
  R7 (2026-09-28) phat hien o `_slice_shape`. nen moi thay doi codegen deu
  phai co buoc kiem tra rieng tren IL, khong dua vao test.

  Script nay:
    1. bien dich .tkv voi --emit-il
    2. (tuy chon) cat rieng than mot method
    3. kiem tra -Expect (regex, it nhat 1 lan) va -Forbid (regex, 0 lan)
    4. tra exit code khac 0 neu vi pham

.PARAMETER Source
  Duong dan file .tkv.

.PARAMETER Entry
  Ten ham entry (mac dinh: bo trong, dung mac dinh cua tkvc).

.PARAMETER Method
  Chi kiem tra than cua method nay. RONG = kiem tra ca assembly.

.PARAMETER Expect
  Regex BAT BUOC xuat hien.

.PARAMETER Forbid
  Regex KHONG DUOC xuat hien.

.PARAMETER WorkDir
  Thu muc tam cho file .il. Mac dinh $env:TEMP.

.EXAMPLE
  .\assert_il.ps1 -Source k.tkv -Method '_mm32' -Expect 'ldobj','Vector4' -Forbid 'conv\.i8'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$Entry = '',
    [string]$Method = '',
    [string[]]$Expect = @(),
    [string[]]$Forbid = @(),
    [string[]]$ExpectCount = @(),
    [string]$WorkDir = $env:TEMP,
    [string]$Compiler = 'D:\TokenVector\dist\tkvc.exe'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Compiler)) {
    throw "khong tim thay compiler: $Compiler"
}
if (-not (Test-Path -LiteralPath $Source)) {
    throw "khong tim thay source: $Source"
}

$base = [System.IO.Path]::GetFileNameWithoutExtension($Source)
$outExe = Join-Path $WorkDir "$base.assertil.exe"
$ilFile = "$outExe.il"

foreach ($f in @($outExe, $ilFile)) {
    if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
}

# --- 1. bien dich voi --emit-il -------------------------------------------
$argList = @('build', $Source, '--out', $outExe, '--emit-il')
if ($Entry) { $argList += @('--entry', $Entry) }
& $Compiler @argList | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outExe)) {
    throw "tkvc build that bai: $Source"
}
if (-not (Test-Path -LiteralPath $ilFile)) {
    throw "khong co file .il - khong the kiem tra IL: $ilFile"
}

$lines = [System.IO.File]::ReadAllLines($ilFile)

# `powershell.exe -File` KHONG phan tich mang: -Expect 'a','b' se den mot
# chuoi duy nhat "a,b". Nen tach lai tu day, de goi bang -File hoat dong
# y nhu goi trong mot shell.
function Split-Patterns($raw) {
    $out = @()
    foreach ($r in @($raw)) {
        if ($null -eq $r) { continue }
        foreach ($p in ($r -split ',')) {
            $p = $p.Trim()
            if ($p) { $out += $p }
        }
    }
    return $out
}
$Expect = Split-Patterns $Expect
$Forbid = Split-Patterns $Forbid
$ExpectCount = Split-Patterns $ExpectCount

# --- 2. cat than method (neu chi dinh) ------------------------------------
$scan = $lines
$scope = 'assembly'
if ($Method) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '\.method\b' -and $lines[$i] -match ("'" + [regex]::Escape($Method) + "'")) {
            $start = $i
            break
        }
    }
    if ($start -lt 0) {
        throw "khong tim thay method '$Method' trong IL cua $base"
    }
    $end = $lines.Count
    for ($i = $start + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\}') { $end = $i; break }
    }
    $scan = $lines[$start..$end]
    $scope = "method '$Method' (dong $($start + 1)..$($end + 1))"
}
$text = ($scan -join "`n")

Write-Host "assert_il: $base  scope=$scope  lines=$($scan.Count)"

# --- 3. kiem tra ---------------------------------------------------------
$fail = 0
foreach ($p in $Expect) {
    $n = ([regex]::Matches($text, $p)).Count
    if ($n -ge 1) {
        Write-Host ("  [ OK ] expect  {0,-40} x{1}" -f $p, $n) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] expect  {0,-40} x0" -f $p) -ForegroundColor Red
        $fail++
    }
}
foreach ($p in $Forbid) {
    $n = ([regex]::Matches($text, $p)).Count
    if ($n -eq 0) {
        Write-Host ("  [ OK ] forbid  {0,-40} x0" -f $p) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] forbid  {0,-40} x{1}" -f $p, $n) -ForegroundColor Red
        # in dong vi pham de khong phai do moi
        $scan | Select-String -Pattern $p | Select-Object -First 5 | ForEach-Object {
            Write-Host ("         > " + $_.Line.Trim()) -ForegroundColor DarkYellow
        }
        $fail++
    }
}
# -ExpectCount: kiem tra SO LAN DUNG, dang "regex=so". Cần khi khong phân
# biệt duoc "lenh do bien dich sinh ra" voi "lenh do test khac sinh ra" -
# vi du `ldind.r4` trong v4mem.tkv den tu read_f32 cua chinh test, nen
# `-Forbid ldind.r4` se do fail ngoai y muon, con `-ExpectCount
# 'ldobj.*Vector4=3'` + `'ldind\.r4=4'` thi noi chinh xac vector path
# them 0 lenh doc scalar nao.
foreach ($spec in $ExpectCount) {
    $parts = $spec -split '=', 2
    if ($parts.Count -ne 2) {
        Write-Host ("  [FAIL] expect_count cu format 'regex=so': " + $spec) -ForegroundColor Red
        $fail++
        continue
    }
    $pat = $parts[0].Trim()
    $want = 0
    if (-not [int]::TryParse($parts[1].Trim(), [ref]$want)) {
        Write-Host ("  [FAIL] expect_count khong parse duoc so: " + $spec) -ForegroundColor Red
        $fail++
        continue
    }
    $got = ([regex]::Matches($text, $pat)).Count
    if ($got -eq $want) {
        Write-Host ("  [ OK ] count    {0,-40} x{1}" -f $pat, $got) -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] count    {0,-40} x{1} (can x{2})" -f $pat, $got, $want) -ForegroundColor Red
        $fail++
    }
}

if ($fail -gt 0) {
    Write-Host "assert_il: FAIL ($fail)" -ForegroundColor Red
    exit 1
}
Write-Host "assert_il: PASS" -ForegroundColor Green
exit 0
