# -*- coding: utf-8 -*-
# DO LUONG CORPUS py2tkv - cong cu de BIET DANG Tien hay Lui.
#
# Ly do ton tai: con so "bao nhieu file bien dich duoc" da ngung mang thong
# tin. Nhiem vu vua sua nhieu loi GOC (docstring, method thoat khoi class, `;`,
# `can_fold_module` nguoc, `return 0` sai pham vi) nhung khong file nao duoi
# gan de ghi them mot con so. Cong cu nay do thu con do:
#
#   1. Phan loai blocker cua TUNG file vao mot NHOM, de biet ton lai
#      nhom nao, va nhom nao da DONG.
#   2. So sanh voi trang thai da luu (`py2tkv_corpus_state.txt`) va in ra
#      thay doi - nen TIEN BO va HOI QUY deu lo ra.
#   3. Dem so HAM HA CAP (bi ha cap) - tinh trang bien dich duoc nhung
#      chay sai, phai bao cao chu khong duoc goi la PASS.
#
# CONG CU DO, KHONG phai gate: luon exit 0. Co `-Update` de ghi lai trang
# thai, mac dinh KHONG ghi - mot lan do khong duoc lam mat lich su.
param(
  [switch]$Update,
  [string]$Khai = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$py2tkv = Join-Path $root "build\py2tkv.exe"
$tkvc = Join-Path $root "dist\tkvc-tv.exe"
$state = Join-Path $root "tools\py2tkv_corpus_state.txt"

if (-not (Test-Path -LiteralPath $py2tkv)) {
  Write-Output "THIEU converter: $py2tkv"
  Write-Output "Build truoc: dist\tkvc-tv.exe tools\py2tkv.tkv build\py2tkv.exe main"
  exit 0
}

# Fixture cua gate khong tinh vao corpus goc.
$fixture = @("features.py","file_io.py","module_const.py","stdlib_map.py",
             "string_cat.py","types.py","proc_run.py","py_module_code.py",
             "tuple_khong_khop.py","base_class_cham_trong.py")

# CHIET phai la phan cach nhom, KHONG phai dau ngoac thuc. Viet `\(...\)` se
# khop CHUOI `(build)` trong duong dan va khong loai gi - corpus phinh to len
# 47 file thay vi 21.
$skip = '(^|\\)(\.git|build|dist|tokenvector-grammar|venv|\.venv|site-packages|__pycache__)(\\|$)'

function Get-Bucket([string]$msg) {
  if ($msg -eq "") { return "PASS" }
  if ($msg -match 'khong phai bien da khai bao') { return "PY_ONLY_API" }
  if ($msg -match 'Chi ho tro dinh nghia ham/class-record top-level') { return "MODULE_LEVEL" }
  if ($msg -match 'record khong co field|base class phai la|trung ten ham|than ham rong|class dang record') { return "STRUCTURE_CLASS" }
  if ($msg -match 'khong tra ve tuple|ben phai phai la 1 tuple') { return "TUPLE_RETURN" }
  if ($msg -match 'khong suy duoc kieu|thieu return-type annotation|chua duoc khai bao|ky vong dtype|chua duoc gan') { return "TYPE_INFER" }
  if ($msg -match 'con thua token|khong tokenize duoc|gap .* token') { return "SYNTAX" }
  if ($msg -match 'chi nhan dung \d+ tham so|for n in dir|exec\(|ky vong') { return "BUILTIN_SHAPE" }
  if ($msg -match 'khong tim thay ham entry') { return "NO_ENTRY" }
  return "OTHER"
}

$tmp = Join-Path $env:TEMP ("py2tkv_corpus_" + [Guid]::NewGuid().ToString("N").Substring(0,8))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$files = @(Get-ChildItem -Path $root -Recurse -Filter *.py -File |
  Where-Object { $_.FullName -notmatch $skip -and $fixture -notcontains $_.Name } | Sort-Object FullName)

$rows = @()
foreach ($f in $files) {
  $base = ($f.FullName -replace '[:\\]', '_')
  $tkv = Join-Path $tmp "$base.tkv"
  $exe = Join-Path $tmp "$base.exe"
  Remove-Item -LiteralPath $exe -ErrorAction SilentlyContinue

  $out = & $py2tkv $f.FullName $tkv --khai $Khai 2>&1 | Out-String
  $haCap = ([regex]::Matches($out, 'HA CAP:')).Count

  $err = & $tkvc $tkv $exe main 2>&1 | Select-String -Pattern '^\[tkvc\] loi' | Select-Object -First 1
  $raw = ""
  if ($err) { $raw = (($err.Line -replace '^.*?tkv: ', '') -split ' - ')[0] }
  elseif (-not (Test-Path -LiteralPath $exe)) { $raw = "KHONG SINH RA .exe" }

  # Uu tien NGUYEN NHAN GOC hon trieu chung. Mot import Python ma khong co ban
  # tuong duong se bien thanh loi kieu lan truyen ("khong suy duoc kieu PHAN TU
  # cua list") - bao cao loi kieu lam nguoi sac sai cho co sua duoc.
  # NGUYEN NHAN GOC khong phai LY DO CHAN. Mot file co `numpy` van co the
  # bien dich duoc (ham dung numpy se bi HA CAP). Nu ep `PY_ONLY_API` lam NHOM,
  # da mat tin hieu "file da bien dich" - `py_ref_f32.py` la vi du.
  $pyOnly = ([regex]::Matches($out, 'PY-ONLY:')).Count
  $localImp = ([regex]::Matches($out, 'LOCAL-IMPORT:')).Count
  $bucket = Get-Bucket $raw

  $goc = ""
  if ($pyOnly -gt 0) { $goc = "$pyOnly import Python-only" }
  elseif ($localImp -gt 0) { $goc = "$localImp module cung du an" }

  $detail = $raw
  if ($detail.Length -gt 52) { $detail = $detail.Substring(0, 52) }
  $rows += [pscustomobject]@{
    Ten = $f.Name; Bucket = $bucket; HaCap = $haCap; Detail = $detail; Goc = $goc
  }
}

Write-Output "=== CORPUS: $($rows.Count) file .py (khong tinh fixture gate)"
Write-Output ""
Write-Output ("{0,-30} {1,-15} {2,5}  {3,-26} {4}" -f "FILE", "NHOM", "HA CAP", "CHI TIET", "NGUYEN NHAN GOC")
foreach ($r in $rows) {
  Write-Output ("{0,-30} {1,-15} {2,5}  {3,-26} {4}" -f $r.Ten, $r.Bucket, $r.HaCap, $r.Detail, $r.Goc)
}

Write-Output ""
Write-Output "=== TONG THEO NHOM"
$rows | Group-Object Bucket | Sort-Object Name | ForEach-Object {
  Write-Output ("  {0,-16} {1,3}  ({2})" -f $_.Name, $_.Count, (($_.Group | ForEach-Object { $_.Ten }) -join ", "))
}
$pass = @($rows | Where-Object { $_.Bucket -eq "PASS" }).Count
$cap = ($rows | Measure-Object -Property HaCap -Sum).Sum
Write-Output ""
Write-Output "BIEN DICH DUOC: $pass/$($rows.Count)   |   HAM BI HA CAP: $cap"

# --- so sanh voi trang thai da luu -----------------------------------------
$cur = @{}
foreach ($r in $rows) { $cur[$r.Ten] = $r.Bucket + "|" + $r.HaCap }
$old = @{}
if (Test-Path -LiteralPath $state) {
  foreach ($ln in [System.IO.File]::ReadAllLines($state)) {
    if ($ln -match '^\s*([^|]+)\|(.+)\|(\d+)') { $old[$Matches[1].Trim()] = $Matches[2] + "|" + $Matches[3] }
  }
}

$changed = @()
foreach ($k in $cur.Keys) {
  if (-not $old.ContainsKey($k)) { $changed += "  + $k : $($cur[$k])" }
  elseif ($old[$k] -ne $cur[$k]) { $changed += "  ~ $k : $($old[$k])  ->  $($cur[$k])" }
}
foreach ($k in $old.Keys) { if (-not $cur.ContainsKey($k)) { $changed += "  - $k : mat khoi corpus" } }

Write-Output ""
if ($old.Count -eq 0) {
  Write-Output "=== CHUA CO TRANG THAI LUU. Chay lai voi -Update de tao."
} elseif ($changed.Count -eq 0) {
  Write-Output "=== KHONG DOI SO VOI TRANG THAI LUU ($($old.Count) file)"
} else {
  Write-Output "=== THAY DOI SO VOI TRANG THAI LUU:"
  $changed | Sort-Object | ForEach-Object { Write-Output $_ }
}

if ($Update) {
  $lines = @("# Trang thai corpus py2tkv - sinh boi tools\py2tkv_corpus.ps1 -Update")
  $lines += "# Do la SO DO, khong phai gate. De cap nhat: chay lai voi -Update"
  foreach ($k in ($cur.Keys | Sort-Object)) {
    $p = $cur[$k] -split '\|'
    $lines += "$k|$($p[0])|$($p[1])"
  }
  [System.IO.File]::WriteAllLines($state, $lines, (New-Object System.Text.UTF8Encoding($false)))
  Write-Output ""
  Write-Output "DA GHI: $state"
}

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
exit 0