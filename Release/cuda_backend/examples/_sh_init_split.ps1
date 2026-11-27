$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$base=Get-Content 'ilgpt2_shInit.tkv' -Raw
$base=$base.Replace("`r`n","`n")
$lines=@{
 'toh3'='        rc = toh3(th3, wqd, wkd, wvd, shQKV + so3, H * H)'
 'toho'='        rc = toh(th, wod, shO + soh, sHH)'
 'toh1'='        rc = toh(th, w1d, sh1 + sof, H * F)'
 'toh2'='        rc = toh(th, w2d, sh2 + sof, H * F)'
 'toht'='        rc = toht(tht, w2d, sh2T + sof, H * F, F)'
}
foreach($k in $lines.Keys){ Write-Host ($k+' hits='+([regex]::Matches($base,[regex]::Escape($lines[$k]))).Count) }
$sets=@{'A'=@('toho','toh1','toh2','toht'); 'B'=@('toh3','toht'); 'C'=@('toh3','toho','toh1','toh2')}
foreach($tag in $sets.Keys){
  $s=$base
  foreach($k in $sets[$tag]){ $s=$s.Replace($lines[$k]+"`n",'') }
  Set-Content ('ilgpt2_shInit'+$tag+'.tkv') -Value $s -NoNewline -Encoding UTF8
  & '..\..\dist\tkvc-tv.exe' ('ilgpt2_shInit'+$tag+'.tkv') ('ilgpt2_shInit'+$tag+'.exe') run --emit-il 2>&1 | Select-Object -First 2
}
