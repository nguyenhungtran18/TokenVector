$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$split='        # logits + loss tu OUT cua lop cuoi'
if(([regex]::Matches($t,[regex]::Escape($split))).Count -ne 1){ throw 'split' }
$parts=$t.Split(@($split),[System.StringSplitOptions]::None)
$fwd=$parts[0]; $bwd=$parts[1]
# forward: restore original scratch outputs / consumers
foreach($pair in @(
 @('zero, qd, T)','zero, dQ, T)'), @('zero, kd, T)','zero, dK, T)'),
 @('zero, vd, T)','zero, dV, T)'), @('zero, ad, T)','zero, dA, T)'),
 @('toh(th, qd, fpA, sQH)','toh(th, dQ, fpA, sQH)'),
 @('toh(th, kd, fpB, sQH)','toh(th, dK, fpB, sQH)'),
 @('toh(th, vd, fpB, sQH)','toh(th, dV, fpB, sQH)'),
 @('toh(th, ad, fpA, sQH)','toh(th, dA, fpA, sQH)')
)){
 $n=[regex]::Matches($fwd,[regex]::Escape($pair[0])).Count
 Write-Output ('fwd '+$pair[0]+' hits='+$n)
 $fwd=$fwd.Replace($pair[0],$pair[1])
}
# backward: drop big-buffer loads
$a=@'
            qo: "i64" = ll * qb
            qd = qall + qo
            kd = kall + qo
            vd = vall + qo
            ad = aall + qo
'@
if(([regex]::Matches($bwd,[regex]::Escape($a))).Count -ne 1){ throw 'bwd loads' }
$bwd=$bwd.Replace($a,'')
# backward: consumers -> scratch names
foreach($pair in @(
 @('toh(th, ad, fpA, sQH)','toh(th, dA, fpA, sQH)'),
 @('toh(th, vd, fpB, sQH)','toh(th, dV, fpB, sQH)'),
 @('toh(th, kd, fpB, sQH)','toh(th, dK, fpB, sQH)'),
 @('toh(th, qd, fpB, sQH)','toh(th, dQ, fpB, sQH)')
)){
 $n=[regex]::Matches($bwd,[regex]::Escape($pair[0])).Count
 Write-Output ('bwd '+$pair[0]+' hits='+$n)
 $bwd=$bwd.Replace($pair[0],$pair[1])
}
# insert recompute right after yb1 load
$a='            yb1: "i64" = read_i64(AY1, ll * 8)'
if(([regex]::Matches($bwd,[regex]::Escape($a))).Count -ne 1){ throw 'yb1' }
$recalc=@'
            yb1: "i64" = read_i64(AY1, ll * 8)
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
$bwd=$bwd.Replace($a,$recalc)
Set-Content $p -Value ($fwd+$split+$bwd) -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
