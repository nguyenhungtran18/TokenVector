# build_test_adamw.ps1 - dich + chay test_adamw.c (kiem thu M5 fused AdamW/buffer).
$ErrorActionPreference = 'Stop'
$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { $vswhere = "C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$flags = "/nologo /O2 /arch:AVX2 /fp:fast"
cmd /c "call `"$vcvars`" >nul 2>&1 && cl $flags test_adamw.c tkv_simd_native.lib /Fe:test_adamw.exe"
if ($LASTEXITCODE -ne 0) { throw "cl that bai" }

Write-Host "--- chay test_adamw.exe ---"
cmd /c "test_adamw.exe"
Write-Host "exit=$LASTEXITCODE"
