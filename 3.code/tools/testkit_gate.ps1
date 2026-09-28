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
#   .\tools\testkit_gate.ps1
#   .\tools\testkit_gate.ps1 -Compiler ..\dist\tkvc.exe
#
# Exit code 0 only when every test passes.

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
if (-not $Compiler) { $Compiler = Join-Path $code "dist\tkvc.exe" }
if (-not $OutDir)  { $OutDir = Join-Path $env:TEMP "opencode\testkit_gate" }

if (-not (Test-Path $Compiler)) {
  Write-Output "MISSING compiler: $Compiler"
  Write-Output "Build it first: .\build_tkvc.ps1"
  exit 2
}
# Gate output must never land in the repo, or a run leaves hundreds of
# generated .exe files behind.
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$tests = Get-ChildItem (Join-Path $code "Testkit") -Filter "*_test.tkv" | Sort-Object Name
Write-Output "compiler : $Compiler"
Write-Output "tests    : $($tests.Count)"
Write-Output ""

$pass = 0; $buildFail = 0; $testFail = 0; $other = 0; $timeouts = 0
$failures = @()

foreach ($t in $tests) {
  $exe = Join-Path $OutDir "$($t.BaseName).exe"
  if (Test-Path $exe) { Remove-Item $exe -Force }

  # --no-lint matches the established gate: the linter is a library-author
  # tool, and several Testkit files are deliberately minimal.
  & $Compiler build $t.FullName --entry run --out $exe --no-lint 2>&1 | Out-Null
  if (-not (Test-Path $exe)) {
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
  $proc = Start-Process -FilePath $exe -NoNewWindow -PassThru `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr
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

  if ($out -match "\[FAIL\]")  { $testFail++; $failures += "TESTFAIL  $($t.Name)" }
  elseif ($rc -ne 0)           { $other++;    $failures += "EXIT$rc  $($t.Name)" }
  else                         { $pass++ }
  if (-not $KeepOutput) {
    Remove-Item $exe -Force -ErrorAction SilentlyContinue
    Remove-Item $stdout -Force -ErrorAction SilentlyContinue
    Remove-Item $stderr -Force -ErrorAction SilentlyContinue
  }
}

Write-Output "=== SUMMARY (out of $($tests.Count) tests) ==="
"PASS={0,-4} BUILDFAIL={1,-4} TESTFAIL={2,-4} OTHER={3} TIMEOUT={4}" -f $pass, $buildFail, $testFail, $other, $timeouts
Write-Output ""
if ($failures.Count) {
  Write-Output "=== FAILURES ==="
  $failures | ForEach-Object { Write-Output "  $_" }
  Write-Output ""
}
if ($pass -eq $tests.Count) {
  Write-Output "GATE: PASS ($pass/$($tests.Count))"
  exit 0
}
Write-Output "GATE: FAIL ($pass/$($tests.Count))"
exit 1
