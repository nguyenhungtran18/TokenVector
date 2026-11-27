$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_long.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$a='        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'AQ anchor' }
$src=$src.Replace($a,"        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))`n        if ll == 0:`n            print(`"DIAG AQ rc`", rc, read_i64(cell, 0))")
$a='            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, qd, T)'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'gemm anchor' }
$src=$src.Replace($a,"            if ll == 0:`n                print(`"DIAG gemm`", qd, fpA, fpB, wqd, wsrc)`n"+$a)
Set-Content 'ilgpt2_diag.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_diag.tkv' 'ilgpt2_diag.exe' run --emit-il 2>&1 | Select-Object -First 5
