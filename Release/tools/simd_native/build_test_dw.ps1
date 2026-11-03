$ErrorActionPreference = 'Stop'

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$flags = "/nologo /O2 /arch:AVX2 /fp:fast"
cmd /c "call `"$vcvars`" > nul 2>&1 && cl $flags test_dw.c /Fe:test_dw.exe /Fo:test_dw.obj tkv_simd_native.lib"
if ($LASTEXITCODE -ne 0) { throw "cl that bai" }
Write-Host "OK -> test_dw.exe"
