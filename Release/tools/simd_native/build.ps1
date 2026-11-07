# build.ps1 - dich kernel SIMD C (AVX2 + FMA) thanh tkv_simd_native.dll.
# Yeu cau: MSVC (Visual Studio). Chay tu thu muc nay:
#   powershell -ExecutionPolicy Bypass -File build.ps1
# Ket qua: tkv_simd_native.dll (copy vao ../../runtime/).
#
# 4 translation unit:
#   tkv_simd_native.c  /fp:fast     - kernel cu (intrinsics, khong doi bit)
#   tkv_linear_dw.c    /fp:precise  - LinearDwFused: /fp:fast cho phep tai lien
#     ket nen ket qua phu thuoc gia tri dich (do 01/11), precise moi dung thu
#     tu cong cua duong .tkv.
#   tkv_bwd_ops.c      /fp:precise  - YEU CAU #12 Ask A: LN fused / bias / softmax
#   tkv_flash_attn.c   /fp:fast     - flash attention fwd+bwd (port thuat toan,
#     khong bit-exact, relax gate; xem comment o dau file)

$ErrorActionPreference = 'Stop'

$vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "Khong tim thay vswhere.exe - can Visual Studio" }
$vs = & $vswhere -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "Khong tim thay vcvars64.bat trong $vs" }

# MKL (pip wheel mkl-devel 2026.x, xem build\_mkl) - neu CO (TKV_MKL=1) thi
# lien ket MKL vao dll (nhu torch_cpu.dll nhung MKL/oneDNN) thay scipy-openblas.
# MAC DINH KHONG DUNG (TKV_MKL mac dinh = 0 = scipy-openblas): den khi
# TKV_MKL=1 duoc cho phep ro rang, model nghich dao ly do.
# DO: sau khi do, MKL 2026.2 tren Xeon E5-2695 v3 (this machine) cham hon
# scipy-openblas 0.3.34 (mode1 seq1024 ~14.7-19.2 s vs 9.31 s) - xem HANDOFF.
# TKV_LINK_MKL=1; runtime can mkl_avx2.3.dll / mkl_mc3.3.dll / mkl_def.3.dll
# + mkl_core.3.dll / mkl_sequential.3.dll / mkl_intel_thread.3.dll
# + libiomp5md.dll (sao chep benh tkv_simd_native.dll) khi TKV_MKL=1.
$mklLib = Join-Path $PSScriptRoot "..\..\build\_mkl\Library\lib"
$mklInc = Join-Path $PSScriptRoot "..\..\build\_mkl\Library\include"
$useMkl = ($env:TKV_MKL -eq "1") -and (Test-Path (Join-Path $mklLib "mkl_intel_lp64_dll.lib"))
$mklDef = ""
$mklIncArg = ""
$mklLink = ""
if ($useMkl) {
    $mklDef = " /DTKV_LINK_MKL"
    $mklIncArg = " /I`"$mklInc`""
    if ($env:TKV_MKL_SEQ -eq "1") {
        if (-not (Test-Path (Join-Path $mklLib "mkl_sequential_dll.lib"))) { throw "mkl_sequential_dll.lib khong tim thay" }
        $mklLink = " `"$(Join-Path $mklLib 'mkl_intel_lp64_dll.lib')`" `"$(Join-Path $mklLib 'mkl_sequential_dll.lib')`" `"$(Join-Path $mklLib 'mkl_core_dll.lib')`""
        Write-Host "MKL sequential: each GEMM = 1 thread (ta song song ngoai)"
    } else {
        $mklLink = " `"$(Join-Path $mklLib 'mkl_intel_lp64_dll.lib')`" `"$(Join-Path $mklLib 'mkl_intel_thread_dll.lib')`" `"$(Join-Path $mklLib 'mkl_core_dll.lib')`" `"$(Join-Path $mklLib 'libiomp5md.lib')`""
        Write-Host "MKL threaded: $mklInc (linked)"
    }
} else {
    Write-Host "MKL: khong co, dung scipy-openblas qua LoadLibraryA"
}

$base = "/nologo /O2 /arch:AVX2 /c$mklDef$mklIncArg"
cmd /c "call `"$vcvars`" > nul 2>&1 && cl $base /fp:fast tkv_simd_native.c /Fo:tkv_simd_native.obj && cl $base /fp:precise tkv_linear_dw.c /Fo:tkv_linear_dw.obj && cl $base /fp:precise tkv_bwd_ops.c /Fo:tkv_bwd_ops.obj && cl $base /fp:fast tkv_flash_attn.c /Fo:tkv_flash_attn.obj && link /DLL /NOLOGO /OUT:tkv_simd_native.dll tkv_simd_native.obj tkv_linear_dw.obj tkv_bwd_ops.obj tkv_flash_attn.obj$mklLink"
if ($LASTEXITCODE -ne 0) { throw "build that bai" }

$dich = Join-Path (Resolve-Path "..\..\runtime") "tkv_simd_native.dll"
Copy-Item tkv_simd_native.dll $dich -Force
Write-Host "OK -> $dich"
