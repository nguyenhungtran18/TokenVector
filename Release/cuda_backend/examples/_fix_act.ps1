$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$split='        # logits + loss tu OUT cua lop cuoi'
if(([regex]::Matches($t,[regex]::Escape($split))).Count -ne 1){ throw 'split anchor' }
$parts=$t.Split(@($split),[System.StringSplitOptions]::None)
$fwd=$parts[0]; $bwd=$parts[1]

# declare per-layer arrays next to AY1/AZ
$a='    AX1 = alloc_bytes(msz)'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'AX1 anchor' }
$fwd=$fwd.Replace($a,"    AQ = alloc_bytes(msz)`n    AK = alloc_bytes(msz)`n    AV = alloc_bytes(msz)`n    AA = alloc_bytes(msz)`n"+$a)

# allocate per-layer activation buffers in the layer init loop
$a='        rc = cuda_malloc(cell, qb)
        wh = write_i64(AY1, ll * 8, read_i64(cell, 0))'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'AY1 alloc anchor' }
$alloc=@'
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AK, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AV, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AA, ll * 8, read_i64(cell, 0))
'@
$fwd=$fwd.Replace($a,$alloc)

# forward: load per-layer pointers
$a='            s2d = read_i64(AS2, ll * 8)'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'fwd s2d anchor' }
$fwd=$fwd.Replace($a,$a+"`n            qd = read_i64(AQ, ll * 8)`n            kd = read_i64(AK, ll * 8)`n            vd = read_i64(AV, ll * 8)`n            ad = read_i64(AA, ll * 8)")

# forward: GEMM outputs and consumers -> per-layer buffers
foreach($pair in @(
 @('zero, dQ, T)','zero, qd, T)'),
 @('zero, dK, T)','zero, kd, T)'),
 @('zero, dV, T)','zero, vd, T)'),
 @('zero, dA, T)','zero, ad, T)'),
 @('toh(th, dQ, fpA, sQH)','toh(th, qd, fpA, sQH)'),
 @('toh(th, dK, fpB, sQH)','toh(th, kd, fpB, sQH)'),
 @('toh(th, dV, fpB, sQH)','toh(th, vd, fpB, sQH)'),
 @('toh(th, dA, fpA, sQH)','toh(th, ad, fpA, sQH)')
)){
    $n=[regex]::Matches($fwd,[regex]::Escape($pair[0])).Count
    Write-Output ('fwd '+$pair[0]+' hits='+$n)
    $fwd=$fwd.Replace($pair[0],$pair[1])
}

# backward: load per-layer pointers
$a='            s2d = read_i64(AS2, ll * 8)'
if(([regex]::Matches($bwd,[regex]::Escape($a))).Count -ne 1){ throw 'bwd s2d anchor' }
$bwd=$bwd.Replace($a,$a+"`n            qd = read_i64(AQ, ll * 8)`n            kd = read_i64(AK, ll * 8)`n            vd = read_i64(AV, ll * 8)`n            ad = read_i64(AA, ll * 8)")

# backward: consumers only (no GEMM outputs named dQ/dK/dV/dA here)
foreach($pair in @(
 @('toh(th, dA, fpA, sQH)','toh(th, ad, fpA, sQH)'),
 @('toh(th, dV, fpB, sQH)','toh(th, vd, fpB, sQH)'),
 @('toh(th, dK, fpB, sQH)','toh(th, kd, fpB, sQH)'),
 @('toh(th, dQ, fpB, sQH)','toh(th, qd, fpB, sQH)')
)){
    $n=[regex]::Matches($bwd,[regex]::Escape($pair[0])).Count
    Write-Output ('bwd '+$pair[0]+' hits='+$n)
    $bwd=$bwd.Replace($pair[0],$pair[1])
}
Set-Content $p -Value ($fwd+$split+$bwd) -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 5
