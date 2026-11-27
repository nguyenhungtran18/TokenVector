$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_long.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$probes=@(
 @('        print("MARK FWD", step)','P1'),
 @('        rc = gemm16(ch, 0, 1, T, H, V, one, fpA, T, fpB, H, zero, gOUT, T)','P2'),
 @('            # reload THIS layer''s forward activations (no stale shared buffers)','P3'),
 @('            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, sb2t, H, zero, gHH, T)','P4'),
 @('            rc = gelu_bwd(bfn, zd, gHH, gZ, T * F)','P5'),
 @('            rc = gemm16(ch, 0, 1, T, H, F, one, fpA, T, sb1, H, zero, gY2, T)','P6'),
 @('            rc = ln_bwd(lnb, xh2d, gY2, dgam, s2d, gDX2, T, H)','P7'),
 @('            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, sbo, H, zero, gA, T)','P8'),
 @('            rc = sf_bwd(sbk, gP, pd, gS, T)','P9')
)
foreach($pr in $probes){
  $line=$pr[0]; $tag=$pr[1]
  $n=[regex]::Matches($src,[regex]::Escape($line)).Count
  Write-Host ($tag+' hits='+$n)
  if($n -ne 1){ throw $tag }
  $indent='        '
  if($line.StartsWith('            ')){ $indent='            ' }
  $ins=$indent+'print("TRACE '+$tag+'")'
  $src=$src.Replace($line,$ins+"`n"+$line)
}
Set-Content 'ilgpt2_shadowtrace.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shadowtrace.tkv' 'ilgpt2_shadowtrace.exe' run --emit-il 2>&1 | Select-Object -First 5
