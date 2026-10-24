# build_test_packed.ps1 - dich + chay test_packed.c (kiem thu M4 packed GEMM).
$ErrorActionPreference = 'Stop'
$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { $vswhere = "C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$flags = "/nologo /O2 /arch:AVX2 /fp:fast"
cmd /c "call `"$vcvars`" >nul 2>&1 && cl $flags test_packed.c tkv_simd_native.lib /Fe:test_packed.exe"
if ($LASTEXITCODE -ne 0) { throw "cl that bai" }

Write-Host "--- chay test_packed.exe ---"
cmd /c "test_packed.exe"
Write-Host "exit=$LASTEXITCODE"
