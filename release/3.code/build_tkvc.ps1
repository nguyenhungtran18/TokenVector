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
#     (canh tkvc.exe) de plugin_loader.py nap dong luc chay.
#
# Chay: powershell -File build_tkvc.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$staging = Join-Path $root "build\pyinstaller_src"

if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path $staging | Out-Null
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
$splitScript = Join-Path $root "build\_split_il_features.py"
@'
import re, os, sys
root = sys.argv[1]
il_codegen_path = os.path.join(root, "compiler", "il_codegen.tkv")
il_features_dir = os.path.join(root, "compiler", "il_features")
with open(il_codegen_path, encoding="utf-8") as f:
    text = f.read()
core_names = set(re.findall(r"from il_features\.(\w+) import", text))
all_files = sorted(f for f in os.listdir(il_features_dir) if f.endswith(".tkv"))
core = [f for f in all_files if f[:-4] in core_names]
library = [f for f in all_files if f[:-4] not in core_names]
print("\n".join(core))
print("---")
print("\n".join(library))
'@ | Out-File -FilePath $splitScript -Encoding utf8

$splitOutput = python $splitScript $root
$splitIdx = [array]::IndexOf($splitOutput, "---")
$coreFiles = $splitOutput[0..($splitIdx - 1)] | Where-Object { $_ -ne "" }
$libraryFiles = $splitOutput[($splitIdx + 1)..($splitOutput.Length - 1)] | Where-Object { $_ -ne "" }

Write-Output "CORE il_features (${coreFiles.Count} file): $($coreFiles -join ', ')"
Write-Output "LIBRARY il_features (${libraryFiles.Count} file): $($libraryFiles -join ', ')"

foreach ($f in $coreFiles) {
    $src = Join-Path $root "compiler\il_features\$f"
    $destName = [System.IO.Path]::ChangeExtension($f, ".py")
    Copy-Item $src (Join-Path $staging "compiler\il_features\$destName")
}
foreach ($f in $libraryFiles) {
    $src = Join-Path $root "compiler\il_features\$f"
    $destName = [System.IO.Path]::ChangeExtension($f, ".py")
    Copy-Item $src (Join-Path $staging "il_features_library\$destName")
}

Push-Location $staging
try {
    python -m PyInstaller --onefile --name tkvc `
      --distpath (Join-Path $root "dist") `
      --workpath (Join-Path $root "build\pyinstaller") `
      --specpath (Join-Path $root "build") `
      --paths compiler `
      tkv.py
} finally {
    Pop-Location
}

# Sau khi PyInstaller build xong: copy nhom LIBRARY sang dist/il_features/
# (canh tkvc.exe) de plugin_loader.py nap dong luc chay.
$distIlFeatures = Join-Path $root "dist\il_features"
if (Test-Path $distIlFeatures) { Remove-Item -Recurse -Force $distIlFeatures }
New-Item -ItemType Directory -Force -Path $distIlFeatures | Out-Null
Copy-Item (Join-Path $staging "il_features_library\*.py") $distIlFeatures

Write-Output "Da build: $(Join-Path $root 'dist\tkvc.exe')"
Write-Output "Thu vien (${libraryFiles.Count} file) o: $distIlFeatures"
Write-Output "(Nguon staging tam thoi o $staging - co the xoa an toan, khong phai nguon that)"
