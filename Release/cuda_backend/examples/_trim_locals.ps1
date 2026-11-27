$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
foreach($v in @('dQ','dK','dV','dA')){
  $a='    rc = cuda_malloc(cell, qb)
    '+$v+' = read_i64(cell, 0)'
  $n=[regex]::Matches($t,[regex]::Escape($a)).Count
  Write-Host ($v+' hits='+$n)
  if($n -ne 1){ throw $v }
  $t=$t.Replace($a,'')
}
foreach($pair in @(
 @('    rc = cuda_malloc(cell, H * F * 2)','    fpT: "i64" = read_i64(cell, 0)'),
 @('    rc = cuda_malloc(cell, 3 * H * H * 2)','    fpQKV: "i64" = read_i64(cell, 0)')
)){
  $a=$pair[0]+"`n"+$pair[1]
  $n=[regex]::Matches($t,[regex]::Escape($a)).Count
  Write-Host ('fp hits='+$n)
  if($n -ne 1){ throw ('fp '+$pair[1]) }
  $t=$t.Replace($a,'')
}
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 5
$il=Get-Content 'ilgpt2_trainN_clean.il' -Raw
$m=[regex]::Matches($il,'stloc\.s (\d+)')|ForEach-Object{[int]$_.Groups[1].Value}
Write-Host ('max_stloc='+($m|Measure-Object -Maximum|Select-Object -ExpandProperty Maximum))
