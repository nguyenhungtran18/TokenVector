$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
# replace 4 pointer arrays with 4 base pointers
$a="    AQ = alloc_bytes(msz)`n    AK = alloc_bytes(msz)`n    AV = alloc_bytes(msz)`n    AA = alloc_bytes(msz)"
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'array anchor' }
$t=$t.Replace($a,"    QALL = alloc_bytes(8)`n    KALL = alloc_bytes(8)`n    VALL = alloc_bytes(8)`n    AALL = alloc_bytes(8)")
# replace 4 per-layer mallocs with nothing
$a=@'
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AK, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AV, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AA, ll * 8, read_i64(cell, 0))
'@
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'malloc anchor' }
$t=$t.Replace($a,'')
# allocate 4 big buffers after the layer-init loop
$a='    ll = 0
    while ll < NL:'
# find end: anchor just before host scratch section '# host scratch (dung lai)'
$a2='    # host scratch (dung lai)'
if(([regex]::Matches($t,[regex]::Escape($a2))).Count -ne 1){ throw 'scratch anchor' }
$big=@'
    rc = cuda_malloc(cell, NL * qb)
    qall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    kall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    vall: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * qb)
    aall: "i64" = read_i64(cell, 0)
'@
$t=$t.Replace($a2,$big+$a2)
# replace per-layer pointer loads (both loops)
$a='            qd = read_i64(AQ, ll * 8)
            kd = read_i64(AK, ll * 8)
            vd = read_i64(AV, ll * 8)
            ad = read_i64(AA, ll * 8)'
$n=[regex]::Matches($t,[regex]::Escape($a)).Count
Write-Output ('load blocks='+$n)
if($n -ne 2){ throw 'load anchor' }
$new=@'
            qo: "i64" = ll * qb
            qd = qall + qo
            kd = kall + qo
            vd = vall + qo
            ad = aall + qo
'@
$t=$t.Replace($a,$new)
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
