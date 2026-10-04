# -*- coding: utf-8 -*-
# Acceptance gate for the TokenVector compiler: build and run every
# Testkit\*_test.tkv, then report how many passed.
#
# Why this file exists: the project had no committed test runner, so the gate
# lived in a scratch script outside the repo. That is how a tree can be left
# with a compiler that does not even build its own test suite and still look
# green - the 63/63 number came from a harness nobody else could reproduce.
# Committing the harness makes the number checkable by anyone.
#
# Usage (from the repo root):
#   .\tools\testkit_gate.ps1                              # SAN PHAM (tkvc-tv)
#   .\tools\testkit_gate.ps1 -Compiler ..\dist\tkvc.exe   # bootstrap Python
#
# MAC DINH LA `dist\tkvc-tv.exe` - COMPILER TU HOST, TURN SAN PHAM.
# Truoc day mac dinh la `dist\tkvc.exe` (bootstrap Python), nen gate bao
# 118/118 trong khi san pham that chi 72/118. `vong.exe` chi chung minh
# g1 == g2 (compiler bien dich lai chinh no ra chinh no) - NO khong chung
# minh bytecode do CHAY DUNG. Do do, gate mac dinh do san pham, va
# `dist\tkvc.exe` chi de doi khi can so sanh hai compiler.
#
# HANH DONG KHAC BIET giua hai compiler:
#   tkvc.exe    build <src> --entry <e> --out <exe> --no-lint [--emit-il]
#   tkvc-tv.exe <src> <exe> <entry>        va LUON tra exit code 0
#
# Exit code 0 only when every test passes AND every IL assertion holds.

param(
  [string]$Compiler = "",
  [string]$OutDir = "",
  [switch]$KeepOutput,
  # Trai dat 120s cho MOI test. Test nhanh nhat chay < 2s, nhung mot test
  # that su treo se chay mai - va dong trong luon uu tien hon viec bao cao
  # "test do treo" sau 10 phut. Do la ly do mac dinh nay dat cao hon nhieu.
  [int]$TimeoutMs = 120000
)

$ErrorActionPreference = "Continue"
$code = Split-Path -Parent $PSScriptRoot
if (-not $Compiler) { $Compiler = Join-Path $code "dist\tkvc-tv.exe" }
if (-not $OutDir)  { $OutDir = Join-Path $env:TEMP "opencode\testkit_gate" }

if (-not (Test-Path $Compiler)) {
  Write-Output "MISSING compiler: $Compiler"
  Write-Output "Build it first: .\build_tkvc.ps1"
  exit 2
}
# Gate output must never land in the repo, or a run leaves hundreds of
# generated .exe files behind.
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$tests = Get-ChildItem (Join-Path $code "tests") -Filter "*_test.tkv" | Sort-Object Name
Write-Output "compiler : $Compiler"
Write-Output "tests    : $($tests.Count)"
Write-Output ""

# ---- IL ASSERTIONS (P6-3, 2026-09-29) ---------------------------------------
# MOT TEST TOI THU SAN KHONG BAO VE TINH DUNG CUA TRANSFORM.
#
# P6 bien dich mot vong lap thanh dang vector + duoi scalar. Neu transform chi
# "chay sai" ma van ra ket qua DUNG - vi du bien dich tam thoi ve 0, hoac roi
# khoi luong dem - moi test van PASS. Con neu transform bi TAT im lang (dang
# vector khong khop mau, bien dich loi, feature bi go), moi test cung van PASS:
# code chay duong scalar binh thuong, ket dung.
#
# Do la lo so khong the bo qua o noi bien doi SILENT. Da gap that: ban test
# dau tien cho ra dung toan bo gia tri o n=8 trong khi vector hoa chua bao gio
# chay. Chi co cach doc IL moi phan biet duoc.
#
# `Must` = chuoi PHAI xuat hien trong .il. `MustNot` = chuoi PHAI KHONG.
# Voi p6_vectorize_test.tkv, cac gia tri hien tai (2026-09-29) la:
#   stobj x3   - 3 ham duoc vector hoa: add_case, chain_case, copy_case
#                (mul_case/div_case co hang so nen bi tu choi dung chu dich)
#   ldobj x9   - 7 loi goi v_load4 + 2 ben trong TkvInt::CompareTo (khong
#                lien quan, chi de ghi nho khi so sanh)
#   _vstart x6, _tstart x6 - nhan vector + nhan duoi scalar, moi ham 2 loi
#                (moi nhan xuat hien 1 lan o `label:` va 1 lan o lenh `br`)
$ilChecks = @(
  @{
    Test    = "p6_vectorize_test.tkv"
    Must    = @("stobj", "_vstart", "_tstart")
    MustNot = @()
  }
)

# ---- STDIN CHO TEST CAN DU LIEU VAO (2026-09-29) -----------------------------
# `input_py_tree_test` goi `input()` de doc chuoi tu stdin. Gate chay exe ma
# khong nen stdin, nen `input()` luon nhan rong va test that bat - MOT TEST LUON
# FAIL, nhung do gate bao xanh (xem "FAIL DETECTION" o tren). Bang cach cap
# stdin dung noi dung, test lai hermetic.
$stdinData = @{
  "input_py_tree_test" = "world`nsecond`n"
}

# ---- WORKING DIRECTORY -------------------------------------------------------
# Mot so test do duong tuong doi so voi thu muc dang chay - vi du
# `path_isfile_isdir_test` hoi `path_isfile("path_isfile_isdir_test.tkv")` va
# `path_isdir(".")`. Chay exe o thu muc con (gate duoi day la noi .tkv nguon
# nam) thi ho khong con dung noi dung nen test that. Cung la, mot test nao do
# vong tinh tuy thu muc hien tai cung se dung mot lan khi gate duoc chay o
# cho khac - nen thu muc lam cong lai cho TAT CA test, khong de may may.
$workDir = Join-Path $code "tests"

$pass = 0; $buildFail = 0; $testFail = 0; $other = 0; $timeouts = 0
$failures = @()

# --- ADAPTER CHO COMPILER TU HOST -------------------------------------------
# Hai compiler KHAC NHAU ve CLI, va truoc day chi co mot trong hai duoc gate:
#   dist\tkvc.exe   (bootstrap Python) : tkvc build <src> --entry <e> --out <exe> --no-lint [--emit-il]
#   dist\tkvc-tv.exe (TU HOST, san pham) : tkvc <src> <exe> <entry>   - KHONG co flag
#
# `tkvc-tv` LUON tra process exit code 0, ke ca khi bien dich that bai, nen
# phai doc stdout tim `[tkvc] loi` - khong the tin vao exit code.
#
# VI SAO PHAI CO: `vong.exe` chi chung minh g1 == g2 (compiler bien dich lai
# chinh no ra chinh no). NO khong chung minh bytecode do CHAY DUNG tren chuong
# trinh that. Truoc khi co adapter nay, KHONG gate nao chay mot dong lenh nao
# qua `tkvc-tv` - nen moi bug chi xuat hien o compiler san pham deu nhin sau
# duoi qua 118/119 PASS cua gate.
$posCli = ($Compiler -like "*tkvc-tv*")
Write-Output "compiler : $Compiler"
if ($posCli) {
  Write-Output "CLI      : TU HOST (vi tri) - doc loi qua stdout, exit code khong dung duoc"
}

function Invoke-TkvBuild([string]$src, [string]$exe, [string]$entry, [string[]]$extra) {
  Remove-Item $exe -Force -ErrorAction SilentlyContinue
  if ($posCli) {
    $b = & $Compiler $src $exe $entry 2>&1 | Out-String
    if ($b -match '\[tkvc\] loi') { return @($false, $b) }
    return @((Test-Path $exe), $b)
  }
  $argv2 = @('build', $src, '--entry', $entry, '--out', $exe, '--no-lint') + $extra
  $b = & $Compiler @argv2 2>&1 | Out-String
  return @((Test-Path $exe), $b)
}

foreach ($t in $tests) {
  $exe = Join-Path $OutDir "$($t.BaseName).exe"
  # --no-lint matches the established gate: the linter is a library-author
  # tool, and several Testkit files are deliberately minimal.
  $r = Invoke-TkvBuild $t.FullName $exe 'run' @()
  if (-not $r[0]) {
    $buildFail++; $failures += "BUILDFAIL  $($t.Name)"; continue
  }

  # TIMEOUT (2026-09-28): chay qua Start-Process de co WaitForExit co gio
  # han. Tren Windows, mot exe TokenVector TREO VONG HAN khong bao gio quay
  # lai - `& $exe` se treo ca gate, va nguoi dung chi con cach Ctrl+C.
  # Do la thu duoc gap thuc te khi them 'try/except/else': bien dich than
  # cong, chay treo, va gate nao cung treo theo. Bay moi loai do duoc bat
  # nhu mot ket qua FAIL, khong phai lam treo ca phan con lai.
  $stdout = Join-Path $OutDir "$($t.BaseName).out"
  $stderr = Join-Path $OutDir "$($t.BaseName).err"
  $stdinFile = $null
  if ($stdinData.ContainsKey($t.BaseName)) {
    $stdinFile = Join-Path $OutDir "$($t.BaseName).in"
    # [IO.File]::WriteAllText chu khong phai Set-Content: PowerShell 5.1 mac
    # dinh ghi UTF-8 **co BOM**, va BOM se chen vao dau dong du lieu vao lam
    # input() nhan ra "﻿world" thay vi "world".
    [IO.File]::WriteAllText($stdinFile, $stdinData[$t.BaseName],
                            (New-Object System.Text.UTF8Encoding $false))
  }
  if ($stdinFile) {
    $proc = Start-Process -FilePath $exe -NoNewWindow -PassThru `
      -WorkingDirectory $workDir `
      -RedirectStandardInput $stdinFile `
      -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  } else {
    $proc = Start-Process -FilePath $exe -NoNewWindow -PassThru `
      -WorkingDirectory $workDir `
      -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  }
  # Bat buoc: doc `$proc.Handle` TRUOC khi choi. Tren .NET, tien trinh da
  # ket thuc se khong tra ExitCode neu doi tuong Process chua giu handle -
  # nen `Start-Process -PassThru` + `WaitForExit` + `$proc.ExitCode` tra
  # NULL (khong loi) va moi test bi ghi nham la 'EXIT'. Day la lam lua
  # kinh dien cua PowerShell, va no da lam ca gate bao FAIL 0/71.
  $null = $proc.Handle
  $finished = $proc.WaitForExit($TimeoutMs)
  if (-not $finished) {
    # Kill ca Cay tien trinh - mot exe co the da spawn con.
    try { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } catch {}
    $other++; $failures += "TIMEOUT   $($t.Name) (qua ${TimeoutMs}ms)"
    $timeouts++
    if (-not $KeepOutput) {
      Remove-Item $exe -Force -ErrorAction SilentlyContinue
    }
    continue
  }
  $rc = $proc.ExitCode
  $out = ""
  if (Test-Path $stdout) { $out = Get-Content $stdout -Raw -ErrorAction SilentlyContinue }
  if (Test-Path $stderr) { $out += (Get-Content $stderr -Raw -ErrorAction SilentlyContinue) }
  if ($null -eq $out) { $out = "" }

  # FAIL DETECTION (2026-09-29, P6-3).
  #
  # Hai loi o day da lam gate BAO XANH TRONG khi test that su that bai:
  # 1. Regex cu la `\[FAIL\]`, nhung `check()` trong `tkv_test_lib.tkv` in
  #    `FAIL <ten> got=... expected=...` - KHONG co ngoac vuong. Regex do khong
  #    bao gio khop dong nao, nen moi test that bai van duoc dem la PASS.
  # 2. `test_summary` tra ve 1 khi co test that bai, va docstring no noi ro
  #    "dung lam exit code cua chuong trinh" - nhung entry cua exe KHONG truyen
  #    gia tri tra ve ra exit code, nen `$rc` luon la 0.
  #
  # Hai le do doc lap cung sai nen mot test sai van chay qua gate. Bay kiem
  # tra theo DUNG dinh dang that cua lib: dong bat dau bang `FAIL`, va dong
  # tong ket `<so> / <so> PASS` khi hai so khac nhau.
  $failed = ($out -match "(?m)^[ \t]*FAIL[ \t]")
  if (-not $failed) {
    # Dong tong ket: `=== <ten>: <A>/<B> PASS ===`. `total` cong don so
    # check() tra ve 0 (PASS), nen A < B nghia la co check that bai.
    $m = [regex]::Match($out, "(?m)^===[^\r\n]*?:\s*(\d+)\s*/\s*(\d+)\s+PASS")
    if ($m.Success) { $failed = ($m.Groups[1].Value -ne $m.Groups[2].Value) }
  }
  if ($failed)              { $testFail++; $failures += "TESTFAIL  $($t.Name)" }
  elseif ($rc -ne 0)        { $other++;    $failures += "EXIT$rc  $($t.Name)" }
  else                      { $pass++ }
  if (-not $KeepOutput) {
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    Remove-Item $stdout -Force -ErrorAction SilentlyContinue
    Remove-Item $stderr -Force -ErrorAction SilentlyContinue
    if ($stdinFile) { Remove-Item $stdinFile -Force -ErrorAction SilentlyContinue }
  }
}

Write-Output "=== IL ASSERTIONS ($($ilChecks.Count) checks) ==="
$ilFail = 0
foreach ($c in $ilChecks) {
  $src = Join-Path $code "tests\$($c.Test)"
  $stem = Join-Path $OutDir "$([IO.Path]::GetFileNameWithoutExtension($c.Test)).ilassert"
  $exe = "$stem.exe"
  $il  = "$stem.il"
  Remove-Item $exe, $il -Force -ErrorAction SilentlyContinue
  $r = Invoke-TkvBuild $src $exe 'run' @('--emit-il')
  if (-not (Test-Path $il)) {
    $ilFail++; $failures += "ILFAIL    $($c.Test) (khong sinh duoc .il)"; continue
  }
  $text = Get-Content $il -Raw
  $missing = @()
  foreach ($p in $c.Must) {
    if ($text -notmatch [regex]::Escape($p)) { $missing += $p }
  }
  foreach ($p in $c.MustNot) {
    if ($text -match [regex]::Escape($p)) { $missing += "KHONG duoc co: $p" }
  }
  if ($missing.Count) {
    $ilFail++
    $failures += "ILFAIL    $($c.Test) -> $($missing -join ', ')"
    Write-Output "  FAIL  $($c.Test): $($missing -join ', ')"
  } else {
    Write-Output "  ok    $($c.Test)"
  }
  if (-not $KeepOutput) {
    Remove-Item $exe, $il -Force -ErrorAction SilentlyContinue
  }
}
Write-Output ""

# ---- NEGATIVE TESTS: file PHAI bi bien dich THAT BAI ------------------------
# Mot lo test ma gate truoc day KHONG the kiem chung: file ma compiler PHAI
# tu choi. Khong co cach nao viet bang `check()` - noi dung do bien dich thanh
# cong roi moi chay duoc, nen "phai bi tu choi" la thu khong the dat trong
# chinh file do.
#
# Hau qua thi khong nho: nhom loi lon nhat cua du an CHI duoc bao ve bang
# docstring, khong co gi kiem chung gi ca:
#   - negative test cua P6 (bien doi sai phai bi bat)
#   - conditional expression hai nhanh lech kieu (truoc do LAM HONG BO NHO)
#   - field container tren record
#   - match/case pattern khong ho tro
#
# `Testkit/negative/*.tkv` - bien dich THAT BAI thi PASS. File dat them vao
# `Testkit/*.tkv` (het `_test`) nen khong bi vong chay test kia lay.
#
# **Kiem tra ca LY DO**, khong chi "co that bai khong": file bat buoc co dong
# dau tien `# EXPECT-SUBSTRING: <doan>`, va thong bao loi phai CHUA doan do.
# Neu khong, mot file sai chinh ta (say typo lam bien dich that) van PASS -
# giong het loi "test luon xanh" ma gate da tung co.
$negDir = Join-Path $code "tests\negative"
$negPass = 0
$negFail = 0
$negTests = @()
if (Test-Path $negDir) {
  $negTests = Get-ChildItem $negDir -Filter "*.tkv" | Sort-Object Name
}
Write-Output "=== NEGATIVE TESTS ($($negTests.Count) file phai bi tu choi) ==="
foreach ($nt in $negTests) {
  $head = (Get-Content $nt.FullName -TotalCount 1 -ErrorAction SilentlyContinue)
  $want = $null
  if ($head -match '^#\s*EXPECT-SUBSTRING:\s*(.+?)\s*$') { $want = $Matches[1] }
  if (-not $want) {
    $negFail++
    $failures += "NEGFAIL   $($nt.Name) (thieu dong dau tien '# EXPECT-SUBSTRING: ...')"
    Write-Output "  FAIL  $($nt.Name): thieu '# EXPECT-SUBSTRING:'"
    continue
  }
  $nexe = Join-Path $OutDir "neg_$($nt.BaseName).exe"
  $r = Invoke-TkvBuild $nt.FullName $nexe 'run' @()
  $negOk = $r[0]
  $bout = $r[1]
  if ($negOk) {
    # Bien dich THANH CONG -> cai ma phai bi tu choi da khong duoc chan.
    $negFail++
    $failures += "NEGFAIL   $($nt.Name) (BIEN DICH THANH CONG - cai do phai bi tu choi)"
    Write-Output "  FAIL  $($nt.Name): bien dich thanh cong, phai bi tu choi"
  } elseif ($bout -notmatch [regex]::Escape($want)) {
    $negFail++
    $failures += "NEGFAIL   $($nt.Name) (that bai sai LY DO - thieu '$want')"
    Write-Output "  FAIL  $($nt.Name): that bai nhung khong phai ly do mong doi"
  } else {
    $negPass++
    Write-Output "  ok    $($nt.Name) (bi tu choi dung ly do)"
  }
  if (-not $KeepOutput) {
    Remove-Item $nexe -Force -ErrorAction SilentlyContinue
  }
}
Write-Output ""

Write-Output "=== SUMMARY (out of $($tests.Count) tests) ==="
"PASS={0,-4} BUILDFAIL={1,-4} TESTFAIL={2,-4} OTHER={3} TIMEOUT={4} ILFAIL={5} NEG={6}/{7}" -f $pass, $buildFail, $testFail, $other, $timeouts, $ilFail, $negPass, $negTests.Count
Write-Output ""
if ($failures.Count) {
  Write-Output "=== FAILURES ==="
  $failures | ForEach-Object { Write-Output "  $_" }
  Write-Output ""
}
if ($pass -eq $tests.Count -and $ilFail -eq 0 -and $negFail -eq 0) {
  Write-Output "GATE: PASS ($pass/$($tests.Count), negative $($negPass)/$($negTests.Count))"
  exit 0
}
Write-Output "GATE: FAIL ($pass/$($tests.Count), negative $($negPass)/$($negTests.Count))"
exit 1
