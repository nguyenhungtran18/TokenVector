# Build tkvc.exe - standalone TokenVector compiler (khong can Python cai san
# de CHAY, chi can Python + PyInstaller de TU BUILD lai file .exe nay khi
# compiler/*.py thay doi). Chay: powershell -File build_tkvc.ps1
python -m PyInstaller --onefile --name tkvc --distpath dist --workpath build/pyinstaller --specpath build `
  --paths compiler `
  --collect-submodules il_features `
  tkv.py
Write-Output "Da build: dist\tkvc.exe"
