# Build tkvc.exe - standalone TokenVector compiler (core nhe) + thu vien
# rieng canh file .exe (Phase "tach tkvc.exe thanh plugin", 2026-08-12,
# xem docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md).
#
# Cac file nguon trong package nay dung duoi `.tkv` (tkv.tkv, tkv_compile.tkv,
# tokenvector_compile.tkv, compiler/*.tkv) nhung NOI DUNG la Python that (xem
# docstring dau tkv_compile.tkv). Python import system KHONG tu nhan .tkv la
# module - script nay COPY tam moi file .tkv sang .py cung ten trong 2 thu
# muc staging RIENG (KHONG sua file .tkv goc):
#   - staging/compiler/il_features/  : CHI nhom CORE (bi il_codegen.tkv
#     import truc tiep qua 'from il_features.X import ten') - PyInstaller
#     chi thay package nay, tu dong dong goi dung nhom core.
#   - staging/il_features_library/   : nhom LIBRARY (con lai) - KHONG
#     nam trong package 'compiler', PyInstaller KHONG thay nen KHONG
#     dong goi vao exe - sau khi build xong, COPY THANG sang dist/il_features/
#     (canh tkvc.exe) de plugin_loader.py nap dong luc chay. Nhom nay
#     GIU duoi '.tkv' (khong doi sang '.py' nhu nhom CORE - 2026-08-28,
#     xem plugin_loader.py da sua de nhan ca 2 duoi) vi day la thu vien
#     PHAT HANH cong khai canh tkvc.exe, khong phai module Python duoc
#     PyInstaller import truc tiep nhu nhom core.
#
# Chay: powershell -File build_tkvc.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$staging = Join-Path $root "build\pyinstaller_src"

# --- XOA staging: CHI xoa khi co MARKER ---
# 2026-09-30: trước đây xoá thẳng `-Recurse -Force` thư mục staging. Không
# có kiểm tra gì, nên nếu đường dẫn sai (biến $root rỗng/sai) nó sẽ XOÁ NHẦM
# một thư mục khác. Nay chi xoa khi thấy marker do chính build này tạo.
$stagingMarker = Join-Path $staging ".tkv-staging"
if (Test-Path $staging) {
    if (-not (Test-Path $stagingMarker)) {
        Write-Output "TU CHOI xoa '$staging': khong thay marker '$stagingMarker'."
        Write-Output "  Thu muc nay co the khong do build nay tao - KHONG xoa nham."
        Write-Output "  Neu bi that, xoa thu cong roi chay lai."
        exit 1
    }
    Remove-Item -Recurse -Force $staging
}
New-Item -ItemType Directory -Force -Path $staging | Out-Null
New-Item -ItemType File -Force -Path $stagingMarker | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $staging "compiler\il_features") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $staging "il_features_library") | Out-Null

# Entry point + 2 module dung chung o cap goc (LUON core).
Copy-Item (Join-Path $root "tkv.tkv")                 (Join-Path $staging "tkv.py")
Copy-Item (Join-Path $root "tkv_compile.tkv")          (Join-Path $staging "tkv_compile.py")
Copy-Item (Join-Path $root "tokenvector_compile.tkv")  (Join-Path $staging "tokenvector_compile.py")

# compiler/*.tkv NGOAI il_features/ (il_core.py, il_codegen.py, il_dispatch.py,
# typed_dsl_parser.py, plugin_loader.py, ...) -> LUON core, copy nguyen cay.
Get-ChildItem -Path (Join-Path $root "compiler") -Filter "*.tkv" -Recurse |
    Where-Object { $_.DirectoryName -notlike "*il_features*" } |
    ForEach-Object {
        $rel = $_.FullName.Substring((Join-Path $root "compiler").Length + 1)
        $relPy = [System.IO.Path]::ChangeExtension($rel, ".py")
        $dest = Join-Path $staging "compiler\$relPy"
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Copy-Item $_.FullName $dest
    }

# compiler/il_features/*.tkv - phan loai CORE vs LIBRARY qua script Python
# (doc truc tiep il_codegen.tkv de biet module nao dang duoc 'from
# il_features.X import ten' - tu dong cap nhat khi them/bot module,
# khong can sua tay danh sach o day).
#
# 2026-09-30: regex CHI kiem import o CAP DAU DONG (`^from`, khong thu
# thap). Truoc day kiem bat ky `from il_features.X import` kha con thu
# thap, nen MOT cua lenh import LAZILY (trong than ham) da lam module X
# chuyen tu LIBRARY sang CORE. Hai he qua:
#   - `generator_lazy` -> CORE: no dang KY cac line parser cho
#     `yield`/`yield from` khi NAPI. La LIBRARY thi `plugin_loader` nap
#     no luc khoi dong (dang ky truoc khi parse). La CORE thi chi duoc
#     import khi `il_codegen` goi `emit_generator_drain_as_container` -
#     qua muon, nen moi file co `yield from` bi bao
#     `khong dich duoc dong: 'yield from ...'`.
#   - `list_type` -> CORE: bi dong vao `il_codegen.py` (lon file).
# Chi import o cap module moi THAT su keo module vao CORE.
  $splitScript = Join-Path $root "tools\_split_il_features.py"
  $manifest = Join-Path $root "tools\il_features_manifest.txt"
  # 2026-09-30: KHONG con heredoc sinh `_split_il_features.py` o day, va file
  # KHONG con nam trong `build/` (thu muc do bi .gitignore loai nen co che nay
  # se bien mat khi clone). Cả hai file nay da chuyen sang `tools/`.
  $splitOutput = python $splitScript $root
  if ($LASTEXITCODE -ne 0) {
      Write-Output "PHAI LOI PHAN NHOM IL_FEATURES (xem tren) - build dung lai."
      exit 1
  }
$splitIdx = [array]::IndexOf($splitOutput, "---")
$coreFiles = $splitOutput[0..($splitIdx - 1)] | Where-Object { $_ -ne "" }
$libraryFiles = $splitOutput[($splitIdx + 1)..($splitOutput.Length - 1)] | Where-Object { $_ -ne "" }

# Luon dung $($x.Count) chu KHONG dung ${x.Count}: cu chay "ngoac nhon"
# la cum TEN bien, khong phai truy cap thuoc tinh - "${a.Count}" tra RONG
# (khong bao loi), nen dong nay in ra "( file)" ma khong ai do loi.
Write-Output "CORE il_features ($($coreFiles.Count) file): $($coreFiles -join ', ')"
Write-Output "LIBRARY il_features ($($libraryFiles.Count) file): $($libraryFiles -join ', ')"

  foreach ($f in $coreFiles) {
      $src = Join-Path $root "compiler\il_features\$f"
      $destName = [System.IO.Path]::ChangeExtension($f, ".py")
      Copy-Item $src (Join-Path $staging "compiler\il_features\$destName")
  }

  # --- BOOTSTRAP: import TƯỜNG MINH mọi module CORE ---
  # 2026-09-30: day la mau chot cho 2 dieu kien CUNG phai dung:
  #   (a) module CORE phai IMPORT DUOC o runtime -> can nam dung cho PyInstaller
  #       bien dich, va PyInstaller chi biet do khi thay `import` that;
  #   (b) module CORE phai DUOC NAP THAT de lenh `register_*` ben trong no
  #       chay - mot module ma khong ai import thi dang ky khong bao gio xay ra.
  # `metaprogramming.tkv` la vi du cua (b): no duoc day vao CORE vi no import
  # `record_feature`, nhung KHONG module nao import no -> `callable`, `dir`,
  # `hash`, `getattr`, `setattr` deu "khong ton tai" luc bien dich.
  # File nay sinh trong staging (khong phai nguon that) noi import tat ca CORE.
  $bootDir = Join-Path $staging "compiler"
  $bootPath = Join-Path $bootDir "_il_features_bootstrap.py"
  $bootLines = @('# -*- coding: utf-8 -*-', '# SINH BOI build_tkvc.ps1 - xem ghi chu o tren.', '"""Import tuong minh moi module CORE de PyInstaller bien dich va de', 'register_* trong chay. KHONG sua tay file nay."""')
  foreach ($f in $coreFiles) {
      $m = [System.IO.Path]::GetFileNameWithoutExtension($f)
      $bootLines += "import il_features.$m  # noqa: F401,E402"
  }
  Set-Content -Path $bootPath -Value $bootLines -Encoding utf8
  Write-Output "Bootstrap: $($coreFiles.Count) module CORE duoc import tuong minh."
  # Noi bootstrap vao il_codegen.py BUNG (ban staging, khong phai nguon that) -
  # PyInstaller chi bien dich nhung module no THAY qua import tu entry.
  $icPath = Join-Path $staging "compiler\il_codegen.py"
  Add-Content -Path $icPath -Value "`nimport _il_features_bootstrap  # noqa: F401,E402`n" -Encoding utf8
  # 2026-09-30: xoa cache PyInstaller. `--workpath build/pyinstaller` giu ket
  # qua phan tich cua lan build truoc, nen doi phan nhom/doi file .tkv van
  # bi che - build "thanh cong" nhung exe cu rat luu lai (gap: sua 42 module
  # CORE, exe van nem `No module named 'il_features.bytes_type'`).
  $pyiWork = Join-Path $root "build\pyinstaller"
  if (Test-Path $pyiWork) { Remove-Item -Recurse -Force $pyiWork }
foreach ($f in $libraryFiles) {
    # 2026-08-28: nhom LIBRARY (dist/il_features/, NAP DONG luc chay qua
    # plugin_loader.py, KHONG duoc PyInstaller dong bang truc tiep) doi
    # duoi ".tkv" (khac nhom CORE o tren van giu ".py" - CORE duoc
    # PyInstaller import THAT nen bat buoc phai la ".py") - de khi public
    # len GitHub khong con hien nhu file Python "lo lieu" (noi dung VAN
    # la Python that, chi khac ten hien thi) - plugin_loader.py da duoc
    # sua de nhan ca 2 duoi.
    $src = Join-Path $root "compiler\il_features\$f"
    $destName = [System.IO.Path]::ChangeExtension($f, ".tkv")
    Copy-Item $src (Join-Path $staging "il_features_library\$destName")
}

Push-Location $staging
try {
    # PyInstaller ghi log INFO ra stderr; voi ErrorActionPreference="Stop" thi
    # PowerShell coi stderr la loi va ABORT script truoc khi copy ra dist.
    # Tam tat strict trong khoi build, roi kiem tra $LASTEXITCODE thu cong.
    $ErrorActionPreference = "Continue"
    python -m PyInstaller --onefile --name tkvc `
      --distpath (Join-Path $root "dist") `
      --workpath (Join-Path $root "build\pyinstaller") `
      --specpath (Join-Path $root "build") `
      --paths compiler `
      tkv.py
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller that bai voi exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

# Sau khi PyInstaller build xong: copy nhom LIBRARY sang dist/il_features/
# (canh tkvc.exe) de plugin_loader.py nap dong luc chay.
$distIlFeatures = Join-Path $root "dist\il_features"
# --- Xoa dist/il_features: cung phai co marker ---
# File trong day la san pham build, khong phai nguon that. Chi xoa khi thay
# marker; neu khong co marker thi don bang tach file .py/.tkv la du (an toan
# hon la xoa ca thu muc khi build vua hong).
if (Test-Path $distIlFeatures) {
    $distMarker = Join-Path $distIlFeatures ".tkv-library"
    if (Test-Path $distMarker) {
        Remove-Item -Recurse -Force $distIlFeatures
    } else {
        Write-Output "GHI CHU: '$distIlFeatures' khong co marker - don thu cong bang .py/.tkv (khong xoa ca thu muc)."
        Get-ChildItem $distIlFeatures -Include *.tkv, *.py -Recurse | Remove-Item -Force
    }
}
New-Item -ItemType Directory -Force -Path $distIlFeatures | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $distIlFeatures ".tkv-library") | Out-Null
Copy-Item (Join-Path $staging "il_features_library\*.tkv") $distIlFeatures

Write-Output "Da build: $(Join-Path $root 'dist\tkvc.exe')"
Write-Output "Thu vien ($($libraryFiles.Count) file) o: $distIlFeatures"
Write-Output "(Nguon staging tam thoi o $staging - co the xoa an toan, khong phai nguon that)"
