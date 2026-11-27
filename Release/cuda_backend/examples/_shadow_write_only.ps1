$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
function Rep2($s,$old,$new,$tag){
  $n=[regex]::Matches($s,[regex]::Escape($old)).Count
  Write-Host ($tag+' hits='+$n)
  if($n -ne 1){ throw $tag }
  return $s.Replace($old,$new)
}
# new adamw snippet (with shadow writes)
$snip=Get-Content '_adamw_snippet.tkv' -Raw
$pat='(?s)def adamw_init\(\) -> "i64":.*?(?=def wrand\()'
if(([regex]::Matches($t,$pat)).Count -ne 1){ throw 'adamw region' }
$t=[regex]::Replace($t,$pat,$snip)
# restore toht/toh3 snippets (they lived between adamw and wrand)
$t=Rep2 $t 'def wrand(i: "i32", j: "i32", s: "f32") -> "f32":' ((Get-Content '_toht_snippet.tkv' -Raw)+(Get-Content '_toh3_snippet.tkv' -Raw)+'def wrand(i: "i32", j: "i32", s: "f32") -> "f32":') 'snippets'
# shadow allocations + offset locals
$a='    rc = cuda_memset(v2, 0, NL * w2b)'
$t=Rep2 $t $a ($a+@'

    rc = cuda_malloc(cell, NL * 3 * H * H * 2)
    shQKV: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * H * H * 2)
    shO: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * H * F * 2)
    sh1: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * H * F * 2)
    sh2: "i64" = read_i64(cell, 0)
    rc = cuda_malloc(cell, NL * H * F * 2)
    sh2T: "i64" = read_i64(cell, 0)
    zz64: "i64" = 0
    qoff: "i64" = qb
'@) 'shadow buffers'
$a='            uo2: "i64" = ll * w2b'
$t=Rep2 $t $a ($a+"`n            so3: `"i64`" = ll * (3 * H * H * 2)`n            soh: `"i64`" = ll * (H * H * 2)`n            sof: `"i64`" = ll * (H * F * 2)") 'offsets'
# call sites
$calls=@(
 @('rc = adamw_update(afn, read_i64(AWq, ll * 8), gqd, mq + uo, vq + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWq, ll * 8), gqd, mq + uo, vq + uo, shQKV + so3, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWk, ll * 8), gkd, mk + uo, vk + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWk, ll * 8), gkd, mk + uo, vk + uo, shQKV + so3 + qoff, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWv, ll * 8), gvd, mv + uo, vv + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWv, ll * 8), gvd, mv + uo, vv + uo, shQKV + so3 + qoff + qoff, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWo, ll * 8), god, mo + uo, vo + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWo, ll * 8), god, mo + uo, vo + uo, shO + soh, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AW1, ll * 8), g1d, m1 + uo1, v1 + uo1, H * F, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AW1, ll * 8), g1d, m1 + uo1, v1 + uo1, sh1 + sof, zz64, H * F, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AW2, ll * 8), g2d, m2 + uo2, v2 + uo2, F * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AW2, ll * 8), g2d, m2 + uo2, v2 + uo2, sh2 + sof, sh2T + sof, F * H, lr, ac1, ac2, wd)')
)
foreach($c in $calls){ $t=Rep2 $t $c[0] $c[1] ('call '+$c[0].Substring(20,16)) }
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_writeonly.exe' run --emit-il 2>&1 | Select-Object -First 6
$il=Get-Content 'ilgpt2_writeonly.il' -Raw
$m=[regex]::Matches($il,'stloc\.s (\d+)')|ForEach-Object{[int]$_.Groups[1].Value}
Write-Host ('max_stloc='+($m|Measure-Object -Maximum|Select-Object -ExpandProperty Maximum))
