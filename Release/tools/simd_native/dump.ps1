$vs = & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
cmd /c "call `"$vcvars`" 2>&1 && dumpbin /disasm:nobytes tkv_simd_native.dll" | Out-File -Encoding ascii dw.asm
Write-Host "done"
