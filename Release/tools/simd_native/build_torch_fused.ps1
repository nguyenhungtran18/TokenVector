# build_torch_fused.ps1 - dich cau noi ATen (torch_fused.cpp) thanh
# tkv_torch_fused.dll. Yeu cau: MSVC + Python co `torch` (CPU wheel).
# Chay tu thu muc nay:
#   powershell -ExecutionPolicy Bypass -File build_torch_fused.ps1
# Ket qua: tkv_torch_fused.dll (copy vao ../../runtime/).
#
# DLL nay chi chua cac entry TkvTorch* (addmm/gelu/sdpa/...); runtime can
# torch_cpu.dll + c10.dll ... tren PATH (hoac TKV_TORCH_PATH tro toi DLL).
# tkv_simd_native.dll load lazy va fallback duong .tkv khi thieu.

$ErrorActionPreference = 'Stop'

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

$torchDir = (& python -c "import torch,os;print(os.path.dirname(torch.__file__))").Trim()
if (-not (Test-Path $torchDir)) { throw "Khong tim thay torch (python -c import torch)" }
$inc = Join-Path $torchDir "include"
$lib = Join-Path $torchDir "lib"
Write-Host "torch: $torchDir"

$base = "/nologo /O2 /arch:AVX2 /std:c++20 /EHsc /MD /LD"
cmd /c "call `"$vcvars`" > nul 2>&1 && cl $base /I`"$inc`" /I`"$inc\torch\csrc\api\include`" torch_fused.cpp /Fo:torch_fused.obj /link /LIBPATH:`"$lib`" torch.lib torch_cpu.lib c10.lib /OUT:tkv_torch_fused.dll"
if ($LASTEXITCODE -ne 0) { throw "build that bai" }

$dich = Join-Path (Resolve-Path "..\..\runtime") "tkv_torch_fused.dll"
Copy-Item tkv_torch_fused.dll $dich -Force
Write-Host "OK -> $dich"
