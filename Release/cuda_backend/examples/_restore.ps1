$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
# restore missing AY1 allocation
$a='        rc = cuda_malloc(cell, qb)
        wh = write_i64(AX1, ll * 8, read_i64(cell, 0))

        rc = cuda_malloc(cell, stb)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'AY1 anchor' }
$t=$t.Replace($a,'        rc = cuda_malloc(cell, qb)
        wh = write_i64(AX1, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AY1, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, stb)')
# drop unused big buffers
$a='    QALL = alloc_bytes(8)
    KALL = alloc_bytes(8)
    VALL = alloc_bytes(8)
    AALL = alloc_bytes(8)
'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'QALL anchor' }
$t=$t.Replace($a,'')
$a='    rc = cuda_malloc(cell, NL * qb)
    qall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    kall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    vall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    aall: "i64" = read_i64(cell, 0)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'big malloc anchor' }
$t=$t.Replace($a,'    # host scratch (dung lai)')
$a='            qo: "i64" = ll * qb
            qd = qall + qo
            kd = kall + qo
            vd = vall + qo
            ad = aall + qo
'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'loads anchor' }
$t=$t.Replace($a,'')
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 5
