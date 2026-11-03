# build.ps1 - dich kernel SIMD C (AVX2 + FMA) thanh tkv_simd_native.dll.
# Yeu cau: MSVC (Visual Studio). Chay tu thu muc nay:
#   powershell -ExecutionPolicy Bypass -File build.ps1
# Ket qua: tkv_simd_native.dll (copy vao ../../runtime/).
#
# 2 translation unit (YEU CAU #10):
#   tkv_simd_native.c  /fp:fast     - kernel cu (intrinsics, khong doi bit)
#   tkv_linear_dw.c    /fp:precise  - LinearDwFused: /fp:fast cho phep tai lien
#     ket nen ket qua phu thuoc gia tri dich (do 01/11), precise moi dung thu
#     tu cong cua duong .tkv.

$ErrorActionPreference = 'Stop'

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$base = "/nologo /O2 /arch:AVX2 /c"
cmd /c "call `"$vcvars`" > nul 2>&1 && cl $base /fp:fast tkv_simd_native.c /Fo:tkv_simd_native.obj && cl $base /fp:precise tkv_linear_dw.c /Fo:tkv_linear_dw.obj && link /DLL /NOLOGO /OUT:tkv_simd_native.dll tkv_simd_native.obj tkv_linear_dw.obj"
if ($LASTEXITCODE -ne 0) { throw "build that bai" }

$dich = Join-Path (Resolve-Path "..\..\runtime") "tkv_simd_native.dll"
Copy-Item tkv_simd_native.dll $dich -Force
Write-Host "OK -> $dich"
