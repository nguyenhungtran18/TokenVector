# -*- coding: utf-8 -*-
# Gate cho py2tkv - cong cu chuyen .py -> .tkv.
#
# VI SAO GATE NAY LA POWERSHELL, KHONG PHAI TOKENVECTOR:
#   TokenVector KHONG co `subprocess` (xem CLAUDE.md), nen mot file
#   tests\*_test.tkv khong the chay py2tkv.exe roi doc ket qua. Test
#   phai "sinh .tkv roi bien dich no bang chinh compiler" - doi tuong
#   phai lam o ngoai chuong trinh. Do do day cung la ly do cac gate
#   khac cua repo (testkit_gate.ps1, lint_rules_gate.ps1,
#   parity_probe/run.ps1) deu viet bang PowerShell.
#
# GATE KIEM TRA 3 THU cho MOI fixture trong tests\py2tkv\*.py:
#   1. py2tkv sinh ra file .tkv (khong that bai)
#   2. file .tkv do BIEN DICH DUOC boi chinh compiler (tkvc-tv.exe)
#   3. khong con dien tich Python-only, va co cac chuoi PHAI CO
#
# Diem 2 la quan trong nhat: mot transform sinh ra code sai van "trong
# ve hinh thuc". Chi compiler moi bat duoc. Day cung la ly do 3 hoi quy
# cua py2tkv (mat dong cap module, mat hang so, an mat %) ton tai lau
# den khi co gate nao bat - xem docs/TOOLS-TO-TOKENVECTOR.md.
#
# Usage (tu repo root):
#   .\tools\py2tkv_gate.ps1
#   .\tools\py2tkv_gate.ps1 -KeepOutput
#
# Exit 0 chi khi MOI fixture deu dat ca 3 dieu kien.

param(
  [string]$Compiler = "",
  [string]$Converter = "",
  [string]$OutDir = "",
  [switch]$KeepOutput
)

$ErrorActionPreference = "Continue"
$code = Split-Path -Parent $PSScriptRoot
if (-not $Compiler) { $Compiler = Join-Path $code "dist\tkvc-tv.exe" }
if (-not $Converter) { $Converter = Join-Path $code "build\py2tkv.exe" }
if (-not $OutDir) { $OutDir = Join-Path $env:TEMP "opencode\py2tkv_gate" }

if (-not (Test-Path $Compiler)) {
  Write-Output "MISSING compiler: $Compiler"
  Write-Output "Build it: .\compiler_py\build_tkvc.ps1 -DistDir .\dist -BuildDir .\build (or restore dist/tkvc-tv.exe)"
  exit 2
}
if (-not (Test-Path $Converter)) {
  Write-Output "MISSING converter: $Converter"
  Write-Output "Build it first:"
  Write-Output "  .\dist\tkvc-tv.exe tools\py2tkv.tkv build\py2tkv.exe main"
  exit 2
}

# Gate khong bao gi de rong trong repo.
Remove-Item -Recurse -Force $OutDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$fixtures = Get-ChildItem (Join-Path $code "tests\py2tkv") -Filter "*.py" | Sort-Object Name
$negatives = @()
$negDir = Join-Path $code "tests\py2tkv_neg"
if (Test-Path $negDir) {
  $negatives = Get-ChildItem $negDir -Filter "*.py" | Sort-Object Name
}
Write-Output "compiler : $Compiler"
Write-Output "converter: $Converter"
Write-Output "fixtures : $($fixtures.Count)  (+ $($negatives.Count) negative)"
Write-Output ""

# --- KY VONG cho tung fixture ------------------------------------------------
# "can" = chuoi PHAI xuat hien trong .tkv sinh ra (contract cua transform)
# "khong" = chuoi KHONG duoc con lai (Python-only)
$expect = @{
  "types.py" = @{
    can = @('a: "i32"', '-> "i32"', '-> "str"', 'xs: "list[i32]"',
            'items: "list[str]"', '-> "list[str]"', 'v: "f64"',
            'k: "f64" = 2.0', 'flag: "bool"')
    # KHONG dat "bool" vao day: `bool` HOP LE cho tham so/giá trị trả về,
    # chi khong hop le o CAP MODULE (module_const.py moi can kiem tra no).
    khong = @('"int"', '"float"', '"list"', 'list[int]', 'list[str] ->')
  }
  "module_const.py" = @{
    can = @('MAX: "i32" = 10', 'NAME: "str" = "abc"', 'PI: "f64" = 3.14',
            'FLAG: "i32" = 1', 'SIZES: "list[i32]"', 'NAMES: "list[str]"',
            'TABLE: "dict[str,i32]"', 'KEYS: "set[str]"', 'EMPTY: "list[i32]" = []',
            'PAIR: "list[str]" = ["a", "b"]')
    khong = @('= True', '= False', '("a", "b")')
  }
  "file_io.py" = @{
    can = @('read_file(', 'write_file(')
    # KHONG kiem tra "io." - chuoi do trung trong BAT KY ten bien ket thuc bang
    # `io.` (vd `ratio.`) nen khong co y nghia gi. `io.open(` moi la mau can so.
    khong = @('with open(', 'io.open(')
  }
  "stdlib_map.py" = @{
    can = @('sha256_hex(', 'md5_hex(', 'json_dumps(',
            're_search(', 're_match(', 're_findall(', 're_split(', 're_sub(')
    khong = @('hashlib.', 'json.', 're.search', 're.match', 're.findall',
              're.split', 're.sub')
  }
  "features.py" = @{
    can = @('def inner(', 'def outer(', 'acc: "list[str]" = []',
            'vs: "list[i32]" = []')
    khong = @()
  }
  "string_cat.py" = @{
    can = @("s = 'xy'", "return 'pqr'")
    khong = @("'x' 'y'", "'p' 'q' 'r'")
  }
"proc_run.py" = @{
    can = @('proc_ra(', 'PY2TKV_TMP', 'read_file(PY2TKV_TMP)')
    # KHONG kiem tra chu "subprocess" trần: comment `# da bo: import subprocess`
    # do chinh py2tkv sinh ra va LUON chua tu do. Chi kiem tra LOI GOI con lai.
    khong = @('subprocess.run(', 'r.returncode', 'r.stdout', 'r.stderr')
  }
  "py_module_code.py" = @{
    can = @('def __khoi_dong() -> "i32":', 'print("bat dau")',
            '    __khoi_dong()')
    khong = @()
  }
}

$pass = 0
$fail = 0
$problems = @()

# Fixture am: chuoi BAO CAO ma py2tkv phai in ra. Xem phan chay ben duoi.
# Fixture am: chuoi BAO CAO ma py2tkv phai in ra. Xem phan chay ben duoi.
# DUNG NHAC DON: trong chuoi nhay kép PowerShell, dau ` la KY TU ESCAPE, nen
# 'CHAN ...: `try` tai dong' se thanh '... <TAB>ry tai dong' va gate bao sai.
$negExpect = @{
  'mod_try.py'  = 'CHAN cap module: `try` tai dong'
  'mod_tinh.py' = 'CHAN cap module: gia tri TINH LUC CHAY tai dong'
}

foreach ($f in $fixtures) {
  $name = $f.Name
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  $tkv = Join-Path $OutDir "$base.tkv"
  $exe = Join-Path $OutDir "$base.exe"

  # (1) py2tkv co sinh ra file khong?
  $convOut = & $Converter $f.FullName $tkv 2>&1 | Out-String
  if (-not (Test-Path $tkv)) {
    $fail++
    Write-Output "FAIL $base | khong sinh duoc .tkv"
    $problems += "$base : py2tkv khong tao ra file .tkv"
    $convOut.Trim().Split("`n") | Select-Object -First 3 | ForEach-Object { Write-Output "      $_" }
    continue
  }
  $text = [System.IO.File]::ReadAllText($tkv)

  # (3a) chuoi phai co / khong duoc co.
  # Dung .Contains() CHU KHONG dung -like: kieu TokenVector chua dau nhay
  # nhung rat nhieu dau [] nhu `list[i32]`, va -like coi [] la KY TU
  # WILDCARD - se bao "THIEU" sai cho moi chuoi co ngoac vuong.
  $bad = @()
  if ($expect.ContainsKey($name)) {
    foreach ($s in $expect[$name].can) {
      if (-not $text.Contains($s)) { $bad += "THIEU: $s" }
    }
    foreach ($s in $expect[$name].khong) {
      if ($text.Contains($s)) { $bad += "CON LAI: $s" }
    }
  }

  # (2) bien dich duoc khong - tien kiem tra noi dung truoc, de bao cao
  # ca hai loai loi, nguoi doc thay het 1 lan.
  Remove-Item $exe -ErrorAction SilentlyContinue
  $cerr = & $Compiler $tkv $exe main 2>&1 | Select-String -Pattern "^\[tkvc\] loi" | Select-Object -First 1
  if ($cerr) {
    $bad += "BIEN DICH: " + (($cerr -replace '^.*: ', '') -replace '\s+', ' ')
  } elseif (-not (Test-Path $exe)) {
    $bad += "BIEN DICH: khong tao duoc .exe (co the compiler loi chua in ra)"
  }

  if ($bad.Count -eq 0) {
    $pass++
    Write-Output "PASS $base"
  } else {
    $fail++
    Write-Output "FAIL $base"
    $problems += "$base : " + ($bad -join " | ")
    $bad | Select-Object -First 6 | ForEach-Object { Write-Output "      $_" }
  }
}

Write-Output ""
Write-Output "=== py2tkv_gate: $pass/$($fixtures.Count) PASS ==="

# ---- FIXTURE AM (PY2TKV_KHONG_THO_BIEN_DICH) --------------------------------
# Mot so cau truc Python KHONG TON TAI o TokenVector: `try` cap module, gia tri
# cap module tinh luc chay, tuple literal... Nhiem vu cua py2tkv KHONG phai la
# bien dich duoc (lam the se sinh code sai), ma la BAO CAO DUNG va CHI CACH
# SUA. Fixture am kiem tra DUNG hai dieu do:
#   1. file .tkv sinh ra KHONG bien dich duoc (neu "lap lam" thi gate bao loi)
#   2. bao cao phai CHUA dung chuoi dinh danh va chi duong sua
$negPass = 0
$negFail = 0
if ($negatives.Count -gt 0) {
  Write-Output ""
  Write-Output "--- fixture am (py2tkv phai bao cao, khong bien dich) ---"
  foreach ($f in $negatives) {
    $name = $f.Name
    $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
    $tkv = Join-Path $OutDir "neg_$base.tkv"
    $exe = Join-Path $OutDir "neg_$base.exe"
    $rep = & $Converter $f.FullName $tkv 2>&1 | Out-String

    $want = ""
    if ($negExpect.ContainsKey($name)) { $want = $negExpect[$name] }
    $bad = @()

    if ($want -ne "" -and -not $rep.Contains($want)) {
      $bad += "THIEU BAO CAO: $want"
    }
    # phai BIEN DICH that bai
    Remove-Item $exe -ErrorAction SilentlyContinue
    $cerr = & $Compiler $tkv $exe main 2>&1 | Select-String -Pattern "^\[tkvc\] loi" | Select-Object -First 1
    if (-not $cerr -and (Test-Path $exe)) {
      $bad += "VAN BIEN DICH DUOC - trong khi phai that bai (co the py2tkv bo am im ma cau truc)"
    }
    if ($bad.Count -eq 0) {
      $negPass++
      Write-Output "PASS neg/$base"
    } else {
      $negFail++
      Write-Output "FAIL neg/$base"
      $bad | ForEach-Object { Write-Output "      $_" }
    }
  }
  Write-Output ""
  Write-Output "=== py2tkv_gate (am): $negPass/$($negatives.Count) PASS ==="
}

if ($fail -gt 0) {
  Write-Output ""
  Write-Output "TOM TAT:"
  $problems | ForEach-Object { Write-Output "  - $_" }
}
if ($KeepOutput) {
  Write-Output ""
  Write-Output "output giu lai: $OutDir"
} else {
  Remove-Item -Recurse -Force $OutDir -ErrorAction SilentlyContinue
}
if ($fail -gt 0 -or $negFail -gt 0) { exit 1 }
exit 0