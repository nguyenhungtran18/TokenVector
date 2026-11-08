# build_tkv_step124.ps1 - build tkv_step124.dll (D5-2).
# Requires: MSVC (vcvars64.bat from Visual Studio with "Desktop dev with C++").
# Output: tkv_step124.dll in this folder; caller copies it into tools/simd_native/.
$ErrorActionPreference = 'Stop'
$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat" }
$base = "/nologo /O2 /arch:AVX2 /c /MD /D_CRT_SECURE_NO_WARNINGS"
cmd /c "call `"$vcvars`" > nul 2>&1 && cl $base tkv_step124.c /Fo:tkv_step124.obj && link /DLL /NOLOGO /OUT:tkv_step124.dll tkv_step124.obj"
if ($LASTEXITCODE -ne 0) { throw "build that bai" }
Write-Host "OK -> $PSScriptRoot\tkv_step124.dll"
