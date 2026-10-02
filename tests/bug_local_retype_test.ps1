# Regression BUG-3 runner: 2 chuong trinh lech kieu PHAI BI TU CHOI luc
# bien dich (exit != 0 + thong bao ro rang), khong crash, khong im lang;
# 1 chuong trinh widen an toan (f64-list <- int) PHAI VAN BUILD + CHAY DUNG.
# Chay: powershell -File bug_local_retype_test.ps1
$ErrorActionPreference = "Continue"
$tkvc = Join-Path $PSScriptRoot "..\dist\tkvc.exe"
$cases = @(
    @{ f = "bug_local_retype_list.tkv";   tag = "retype_list" },
    @{ f = "bug_local_retype_scalar.tkv"; tag = "retype_scalar" }
)
$fail = 0
foreach ($c in $cases) {
    $src = Join-Path $PSScriptRoot $c.f
    $out = Join-Path $env:TEMP ($c.tag + "_out.exe")
    $log = & $tkvc build $src --entry main --out $out 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        Write-Output "FAIL $($c.tag): build THANH CONG nhung phai bi tu choi"
        $fail = $fail + 1
    } else {
        $msg = ($log -join " ")
        if ($msg -match "SyntaxError|loi|Error") {
            Write-Output "PASS $($c.tag): bi tu choi dung - $($msg.Substring(0, [Math]::Min(160, $msg.Length)))"
        } else {
            Write-Output "FAIL $($c.tag): bi tu choi nhung khong co thong bao ro - $msg"
            $fail = $fail + 1
        }
    }
    if (Test-Path $out) { Remove-Item $out -Force }
}
# Case widen an toan: f64-list <- int elems phai van build + chay dung 4.0
$wsrc = Join-Path $PSScriptRoot "bug_local_retype_widen.tkv"
$outw = Join-Path $env:TEMP "retype_widen_out.exe"
& $tkvc build $wsrc --entry main --out $outw 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Output "FAIL retype_widen: build BI CHAN nhung day la truong hop widen an toan"
    $fail = $fail + 1
} else {
    $got = & $outw
    if ("$got" -match "4") {
        Write-Output "PASS retype_widen: widen f64 <- int van dung ($got)"
    } else {
        Write-Output "FAIL retype_widen: chay sai gia tri - $got"
        $fail = $fail + 1
    }
}
if (Test-Path $outw) { Remove-Item $outw -Force }
if ($fail -gt 0) { Write-Output "bug_local_retype_test: $fail FAIL"; exit 1 }
Write-Output "bug_local_retype_test: PASS 3/3"
exit 0
