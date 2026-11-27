$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$split='        # logits + loss tu OUT cua lop cuoi'
if(([regex]::Matches($t,[regex]::Escape($split))).Count -ne 1){ throw 'split' }
$parts=$t.Split(@($split),[System.StringSplitOptions]::None)
$fwd=$parts[0]; $bwd=$parts[1]
# arrays
$a='    AG2 = alloc_bytes(msz)'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'AG2' }
$fwd=$fwd.Replace($a,$a+"`n    AQ = alloc_bytes(msz)`n    AK = alloc_bytes(msz)`n    AV = alloc_bytes(msz)`n    AA = alloc_bytes(msz)")
# per-layer allocations right after AY1 alloc (keep AY1!)
$a='        rc = cuda_malloc(cell, qb)
        wh = write_i64(AY1, ll * 8, read_i64(cell, 0))'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'AY1 alloc' }
$fwd=$fwd.Replace($a,$a+@'

        rc = cuda_malloc(cell, qb)
        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AK, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AV, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AA, ll * 8, read_i64(cell, 0))
'@)
# forward pointer loads
$a='            s2d = read_i64(AS2, ll * 8)'
if(([regex]::Matches($fwd,[regex]::Escape($a))).Count -ne 1){ throw 'fwd s2d' }
$fwd=$fwd.Replace($a,$a+"`n            qd = read_i64(AQ, ll * 8)`n            kd = read_i64(AK, ll * 8)`n            vd = read_i64(AV, ll * 8)`n            ad = read_i64(AA, ll * 8)")
foreach($pair in @(
 @('zero, dQ, T)','zero, qd, T)'), @('zero, dK, T)','zero, kd, T)'),
 @('zero, dV, T)','zero, vd, T)'), @('zero, dA, T)','zero, ad, T)'),
 @('toh(th, dQ, fpA, sQH)','toh(th, qd, fpA, sQH)'),
 @('toh(th, dK, fpB, sQH)','toh(th, kd, fpB, sQH)'),
 @('toh(th, dV, fpB, sQH)','toh(th, vd, fpB, sQH)'),
 @('toh(th, dA, fpA, sQH)','toh(th, ad, fpA, sQH)')
)){
 $n=[regex]::Matches($fwd,[regex]::Escape($pair[0])).Count
 Write-Output ('fwd '+$pair[0]+' hits='+$n)
 if($n -ne 1){ throw ('fwd '+$pair[0]) }
 $fwd=$fwd.Replace($pair[0],$pair[1])
}
# backward pointer loads
$a='            s2d = read_i64(AS2, ll * 8)'
if(([regex]::Matches($bwd,[regex]::Escape($a))).Count -ne 1){ throw 'bwd s2d' }
$bwd=$bwd.Replace($a,$a+"`n            qd = read_i64(AQ, ll * 8)`n            kd = read_i64(AK, ll * 8)`n            vd = read_i64(AV, ll * 8)`n            ad = read_i64(AA, ll * 8)")
# remove recompute block
$a=@'
            rc = toh(th, yb1, fpA, sQH)
            rc = toh(th, wqd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, dQ, T)
            rc = toh(th, wkd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, dK, T)
            rc = toh(th, wvd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, dV, T)
            rc = toh(th, pd, fpA, sTT)
            rc = toh(th, dV, fpB, sQH)
            rc = gemm16(ch, 0, 0, T, H, T, one, fpA, T, fpB, T, zero, dA, T)
'@
if(([regex]::Matches($bwd,[regex]::Escape($a))).Count -ne 1){ throw 'recompute block' }
$bwd=$bwd.Replace($a,'')
# backward consumers -> per-layer buffers
foreach($pair in @(
 @('toh(th, dA, fpA, sQH)','toh(th, ad, fpA, sQH)'),
 @('toh(th, dV, fpB, sQH)','toh(th, vd, fpB, sQH)'),
 @('toh(th, dK, fpB, sQH)','toh(th, kd, fpB, sQH)'),
 @('toh(th, dQ, fpB, sQH)','toh(th, qd, fpB, sQH)')
)){
 $n=[regex]::Matches($bwd,[regex]::Escape($pair[0])).Count
 Write-Output ('bwd '+$pair[0]+' hits='+$n)
 if($n -ne 1){ throw ('bwd '+$pair[0]) }
 $bwd=$bwd.Replace($pair[0],$pair[1])
}
Set-Content $p -Value ($fwd+$split+$bwd) -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
