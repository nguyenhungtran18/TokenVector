$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$base=Get-Content 'ilgpt2_writeonly.tkv' -Raw
$base=$base.Replace("`r`n","`n")
$a='    t0 = time_perf()'
$t2=@'
    ll = 0
    while ll < NL:
        wqd = read_i64(AWq, ll * 8)
        wkd = read_i64(AWk, ll * 8)
        wvd = read_i64(AWv, ll * 8)
        wod = read_i64(AWo, ll * 8)
        w1d = read_i64(AW1, ll * 8)
        w2d = read_i64(AW2, ll * 8)
        ll = ll + 1
'@
$t3=@'
    ll = 0
    while ll < NL:
        so3 = ll * (3 * H * H * 2)
        soh = ll * (H * H * 2)
        sof = ll * (H * F * 2)
        ll = ll + 1
'@
$s2=$base.Replace($a,$t2+"`n"+$a)
Set-Content 'ilgpt2_shAssignW.tkv' -Value $s2 -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shAssignW.tkv' 'ilgpt2_shAssignW.exe' run --emit-il 2>&1 | Select-Object -First 2
$s3=$base.Replace("`n    qoff: `"i64`" = qb","`n    so3: `"i64`" = 0`n    soh: `"i64`" = 0`n    sof: `"i64`" = 0`n    qoff: `"i64`" = qb")
$s3=$s3.Replace($a,$t3+"`n"+$a)
Set-Content 'ilgpt2_shAssignO.tkv' -Value $s3 -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shAssignO.tkv' 'ilgpt2_shAssignO.exe' run --emit-il 2>&1 | Select-Object -First 2
