# build.ps1 - dich kernel SIMD C (AVX2 + FMA) thanh tkv_simd_native.dll.
# Yeu cau: MSVC (Visual Studio). Chay tu thu muc nay:
#   powershell -ExecutionPolicy Bypass -File build.ps1
# Ket qua: tkv_simd_native.dll (copy vao ../../runtime/).

$ErrorActionPreference = 'Stop'

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$flags = "/nologo /O2 /arch:AVX2 /fp:fast"
cmd /c "call `"$vcvars`" >nul 2>&1 && cl $flags /LD tkv_simd_native.c /Fe:tkv_simd_native.dll /Fo:tkv_simd_native.obj"
if ($LASTEXITCODE -ne 0) { throw "cl that bai" }

$dich = Join-Path (Resolve-Path "..\..\runtime") "tkv_simd_native.dll"
Copy-Item tkv_simd_native.dll $dich -Force
Write-Host "OK -> $dich"
