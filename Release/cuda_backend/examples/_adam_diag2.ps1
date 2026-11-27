$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_long.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$a='    rc = cuda_memset(mq, 0, NL * whb)'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'memset anchor' }
$src=$src.Replace($a,"    mrc: `"i32`" = cuda_memset(mq, 0, NL * whb)`n    print(`"DIAG memset rc`", mrc, NL * whb, mq)")
$a='        print("MARK UPD", step)'
if(([regex]::Matches($src,[regex]::Escape($a))).Count -ne 1){ throw 'mark' }
$ins=@'
        wh = write_f32(hY1, 0, 777777.0)
        dstat: "i32" = cuda_h2d(hY1, mq, 16, 2)
        if step == 1:
            print("DIAG M0", read_f32(hY1, 0), read_f32(hY1, 4), dstat)
'@
$src=$src.Replace($a,$ins+$a)
Set-Content 'ilgpt2_adamdiag.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_adamdiag.tkv' 'ilgpt2_adamdiag.exe' run --emit-il 2>&1 | Select-Object -First 5
