$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_shInit.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
# rename init-loop locals only: isolate the init loop block
$start=$t.IndexOf("    ll = 0`n    while ll < NL:`n        wqd = read_i64(AWq, ll * 8)")
if($start -lt 0){ throw 'init start' }
$end=$t.IndexOf("    t0 = time_perf()",$start)
if($end -lt 0){ throw 'init end' }
$block=$t.Substring($start,$end-$start)
foreach($pair in @(
 @('wqd','iwqd'),@('wkd','iwkd'),@('wvd','iwvd'),@('wod','iwod'),@('w1d','iw1d'),@('w2d','iw2d'),
 @('so3','iso3'),@('soh','isoh'),@('sof','isof')
)){ $block=$block.Replace($pair[0],$pair[1]) }
$t=$t.Substring(0,$start)+$block+$t.Substring($end)
Set-Content 'ilgpt2_shRename.tkv' -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shRename.tkv' 'ilgpt2_shRename.exe' run --emit-il 2>&1 | Select-Object -First 4
