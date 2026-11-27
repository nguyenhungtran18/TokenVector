$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_long.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$a='            rc = gemm16(ch, 0, 1, T, F, H, one, fpA, T, fpB, F, zero, gHH, T)'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'ghh gemm' }
$src=$src.Replace($a,'            rc = cublas_sgemm(ch, 0, 1, T, F, H, one, gOUT, T, w2d, F, zero, gHH, T)')
Set-Content 'ilgpt2_sgemmtest.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_sgemmtest.tkv' 'ilgpt2_sgemmtest.exe' run --emit-il 2>&1 | Select-Object -First 5
