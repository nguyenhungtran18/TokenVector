$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_long.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$a='        ac2: "f32" = 1.0 - b2t'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'ac2' }
$src=$src.Replace($a,$a+"`n        if step == 1:`n            print(`"DIAG adamw`", lr, ac1, ac2, wd, afn, mq, m1)")
$a='        print("MARK UPD", step)'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'mark' }
$src=$src.Replace($a,"        wh = cuda_h2d(hY1, read_i64(AWq, 0), 16, 2)`n        if step == 1:`n            print(`"DIAG W0`", read_f32(hY1, 0), read_f32(hY1, 4))`n"+$a)
Set-Content 'ilgpt2_adamdiag.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_adamdiag.tkv' 'ilgpt2_adamdiag.exe' run --emit-il 2>&1 | Select-Object -First 5
