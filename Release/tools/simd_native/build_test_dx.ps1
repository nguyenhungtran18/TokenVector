# build_test_dx.ps1 - dich + chay test_dx.c (bit-check LinearDxFused vs SgemmFull).
$ErrorActionPreference = 'Stop'
$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

cmd /c "call `"$vcvars`" > nul 2>&1 && cl /nologo /O2 test_dx.c tkv_simd_native.lib /Fe:test_dx.exe"
if ($LASTEXITCODE -ne 0) { throw "compile that bai" }
.\test_dx.exe
exit $LASTEXITCODE
