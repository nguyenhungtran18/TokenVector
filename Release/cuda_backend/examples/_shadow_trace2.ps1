$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_shadowtrace.tkv' -Raw
$src=$src.Replace("`r`n","`n")
$probes=@(
 @('            rc = sf_bwd(sbk, gP, pd, gS, T)','P10'),
 @('            rc = gemm16(ch, 0, 0, T, H, T, hal, fpA, T, fpB, T, zero, gQ, T)','P11'),
 @('            rc = gemm16(ch, 1, 0, T, H, T, hal, fpA, T, fpB, T, zero, gK, T)','P12'),
 @('            rc = gemm16(ch, 1, 0, H, H, T, one, fpA, T, fpB, T, zero, gqd, H)','P13'),
 @('            rc = ln_bwd(lnb, xh1d, gDX2, dgam, s1d, gY1, T, H)','P14'),
 @('        ll = 0
        while ll < NL:
            gqd = read_i64(AGq, ll * 8)','P15')
)
foreach($pr in $probes){
  $line=$pr[0]; $tag=$pr[1]
  $n=[regex]::Matches($src,[regex]::Escape($line)).Count
  Write-Host ($tag+' hits='+$n)
  if($n -ne 1){ throw $tag }
  $indent='            '
  if($line.StartsWith('        ')){ $indent='        ' }
  $src=$src.Replace($line,$indent+'print("TRACE '+$tag+'")'+"`n"+$line)
}
Set-Content 'ilgpt2_shadowtrace.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shadowtrace.tkv' 'ilgpt2_shadowtrace.exe' run --emit-il 2>&1 | Select-Object -First 5
