# -*- coding: utf-8 -*-
# PHAN CUM LOI cua COMPILER TU HOST (dist\tkvc-tv.exe).
#
# Cong cu DO, khong phai gate: khong sua gi, chi bien tung loi bien dich thanh
# CUM de biet nen lam gi truoc. `testkit_gate.ps1` chi cho PASS/BUILDFAIL;
# khi con ~44/118 FAIL, can biet 44 loi do THUOC BAO NHOM NAO.
#
# Vì sao can: mac dinh cua gate da chuyen sang `tkvc-tv.exe` (san pham that).
# Con 40 BUILDFAIL + 4 RUN_FAIL deu CHUA BI DO - day la so do de chon cum.
#
# Cach dung (tu goc du an):
#   .\tools\testkit_cluster.ps1
#   .\tools\testkit_cluster.ps1 -Compiler dist\tkvc.exe    # so sanh bootstrap
param(
  [string]$Compiler = ""
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
if (-not $Compiler) { $Compiler = Join-Path $root "dist\tkvc-tv.exe" }
if (-not (Test-Path $Compiler)) { Write-Output "MISSING compiler: $Compiler"; exit 2 }

$work = Join-Path $env:TEMP ("opencode\cluster_" + [Guid]::NewGuid().ToString("N").Substring(0, 6))
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Chu hoa thong diep loi thanh ten cum. THU TU QUAN TRONG: cum dac biet truoc
# cum chung, vi thong diep dai hon thuong chua cum dac biet.
function Get-Bucket([string]$m) {
  if ($m -eq "") { return "OK" }
  if ($m -match "ham '\w+' khong ton tai") { return "MISSING_BUILTIN" }
  if ($m -match "The given key was not present") { return "COMPILER_INTERNAL" }
  if ($m -match "dung o dang lenh doc lap") { return "NO_STMT_FORM" }
  if ($m -match "khong tra ve tuple|ben phai phai la 1 ") { return "TUPLE" }
  if ($m -match "record khong co field|base class phai la|trung ten ham|than ham rong|dang record") { return "RECORD" }
  if ($m -match "kieu None|gap 'None'") { return "NONE_DTYPE" }
  if ($m -match "chua duoc khai bao|chua duoc gan") { return "UNDECLARED" }
  if ($m -match "chua ho tro doi so kieu|chi ho tro dang thap phan|chi ho tro \d+ tham so") { return "TYPE_RULE" }
  if ($m -match "AST node khong ro") { return "AST_PARSE" }
  if ($m -match "con thua token khong parse duoc|khong tokenize duoc|khong parse duoc factor|khong dich duoc dong") { return "SYNTAX" }
  if ($m -match "loai loi '\w+' khong hop le") { return "EXCEPTION_TYPE" }
  if ($m -match "ky vong") { return "IL_EXPECT" }
  if ($m -match "Chi ho tro dinh nghia ham/class-record top-level") { return "MODULE_LEVEL" }
  return "OTHER"
}

$tests = @(Get-ChildItem (Join-Path $root "tests") -Filter "*_test.tkv" -File | Sort-Object Name)
$rows = @()
foreach ($t in $tests) {
  $exe = Join-Path $work ($t.BaseName + ".exe")
  Remove-Item $exe -Force -ErrorAction SilentlyContinue
  $b = & $Compiler $t.FullName $exe run 2>&1 | Out-String
  $msg = ""
  if ($b -match '\[tkvc\] loi: (.+)') { $msg = $Matches[1] -replace ("^" + [regex]::Escape($t.FullName) + ": "), "" }
  $state = "BUILD_FAIL"
  if ($msg -eq "" -and (Test-Path $exe)) {
    $p = Start-Process -FilePath $exe -NoNewWindow -PassThru -Wait `
      -RedirectStandardOutput (Join-Path $work "o.txt") `
      -RedirectStandardError  (Join-Path $work "e.txt")
    if ($p.ExitCode -eq 0) { $state = "PASS" } else { $state = "RUN_FAIL"; $msg = "exit=$($p.ExitCode)" }
  }
  $rows += [pscustomobject]@{ Ten = $t.Name; State = $state; Bucket = (Get-Bucket $msg); Msg = $msg }
}

Write-Output "=== COMPILER: $Compiler"
Write-Output "=== TONG: $($rows.Count) test"
$rows | Group-Object State | Sort-Object Count -Descending | ForEach-Object {
  Write-Output ("  {0,-12} {1,4}" -f $_.Name, $_.Count)
}
Write-Output ""
Write-Output "=== CUM LOI (chi BUILD_FAIL / RUN_FAIL)"
$bad = @($rows | Where-Object { $_.State -ne "PASS" })
$bad | Group-Object Bucket | Sort-Object Count -Descending | ForEach-Object {
  Write-Output ("  {0,-20} {1,3}" -f $_.Name, $_.Count)
  foreach ($r in ($_.Group | Sort-Object Ten)) {
    $m = $r.Msg
    if ($m.Length -gt 82) { $m = $m.Substring(0, 82) }
    Write-Output ("      {0,-40} {1}" -f $r.Ten, $m)
  }
}
Write-Output ""
Write-Output "=== PASS: $(@($rows | Where-Object { $_.State -eq 'PASS' }).Count)/$($rows.Count)"
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue