# Gate cho bo luat cua tools\tkv_guide.exe.
#
# Chay: powershell -NoProfile -File tools\lint_rules_gate.ps1
#
# VI SAO CO FILE NAY: ngay trong luc chuyen tkv_guide sang TokenVector, luat
# (4) ("buoc slice am") BO SOT `xs[::-1]` - chi bat duoc `xs[:-1]`. Khong
# Testkit nao co slice am, nen quet 117 file ra 0 canh bao tuc la luat CHET ma
# khong ai biet. Het cach "tin regex dung": moi luat deu phai co positive test
# (bat loi) va negative test (khong bao nham).
#
# Tien ich doc UTF-8: `print` cua TokenVector ghi UTF-16LE khi stdout bi
# redirect, nen phai dung --file de lay ket qua.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root 'dist\tkv_guide.exe'
$fix = Join-Path $root 'tools\lint_fixtures'
$tmp = Join-Path $env:TEMP 'tkv_guide_lintgate'
$utf8 = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path $exe)) {
    Write-Error "THIEU $exe - build truoc: powershell -File tools\build_tkv_guide.ps1"
    exit 2
}
if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Path $tmp | Out-Null }

# (so dong, muc do) 1-based - khop voi tools\lint_fixtures\bad.tkv hien tai
$expectBad = @(
    @(11, 'LOI'),          # k: "i32" = 1 - local co annotate kieu
    @(14, 'LOI'),          # fmt_float(7.0, 2) - literal
    @(15, 'LOI'),          # fmt_float(a + b, 2) - bieu thuc
    @(17, 'LOI'),          # xs[::-1]
    @(18, 'LOI'),          # xs[1:-1]
    @(19, 'LOI'),          # xs[2::-1]
    @(24, 'NGHIEM_TRONG'), # except RuntimeError
    @(26, 'LOI')           # z = xs.pop()
)
# Phai KHONG bao: 16 (fmt_float(a,2) hop le), 20 (xs[0:2]), 21 (xs[1:5:2]),
# 27 (str(a + b) hop le).

function Invoke-Lint($file) {
    $out = Join-Path $tmp ([System.IO.Path]::GetFileNameWithoutExtension($file) + '.txt')
    if (Test-Path $out) { Remove-Item $out -Force }
    & $exe lint $file --file $out | Out-Null
    if (-not (Test-Path $out)) { throw "khong co file ket qua $out" }
    $rows = @()
    foreach ($line in [System.IO.File]::ReadAllLines($out, $utf8)) {
        if ($line -match '^.*?:(\d+)\s+\[([A-Z ]+)\]') {
            $rows += , @([int]$Matches[1], $Matches[2].Trim().Replace(' ', '_'))
        }
    }
    return $rows
}

function Compare-Set($label, $got, $want) {
    $fail = 0
    $gotS = ($got | Sort-Object { $_[0] } | ForEach-Object { "$($_[0]):$($_[1])" })
    $wantS = ($want | Sort-Object { $_[0] } | ForEach-Object { "$($_[0]):$($_[1])" })
    foreach ($w in $wantS) {
        if ($gotS -notcontains $w) { Write-Host "   - BO SOT  $w"; $fail++ }
    }
    foreach ($g in $gotS) {
        if ($wantS -notcontains $g) { Write-Host "   - BAO NHAM $g"; $fail++ }
    }
    if ($fail -eq 0) {
        Write-Host ("ok   [{0}] {1} canh bao" -f $label, $got.Count)
    } else {
        Write-Host ("FAIL [{0}]" -f $label)
        Write-Host ("   can  : {0}" -f ($wantS -join ' '))
        Write-Host ("   thuc : {0}" -f ($gotS -join ' '))
    }
    return $fail
}

$fail = 0
$fail += Compare-Set 'FILE CO LOI' (Invoke-Lint (Join-Path $fix 'bad.tkv')) $expectBad
$fail += Compare-Set 'FILE SACH' (Invoke-Lint (Join-Path $fix 'ok.tkv')) @()

Write-Host '----'
if ($fail -gt 0) {
    Write-Host "FAIL $fail"
    exit 1
}
Write-Host 'PASS: bat het loi, khong bao nham'
exit 0
