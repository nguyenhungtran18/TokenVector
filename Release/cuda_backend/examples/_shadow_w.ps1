$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
function Rep($s,$old,$new,$tag){
  $n=[regex]::Matches($s,[regex]::Escape($old)).Count
  Write-Host ($tag+' hits='+$n)
  if($n -ne 1){ throw $tag }
  return $s.Replace($old,$new)
}
# 1. new adamw snippet
$snip=Get-Content '_adamw_snippet.tkv' -Raw
$pat='(?s)def adamw_init\(\) -> "i64":.*?(?=def wrand\()'
if(([regex]::Matches($t,$pat)).Count -ne 1){ throw 'adamw region' }
$t=[regex]::Replace($t,$pat,$snip)
# 2. shadow device buffers
$a='    rc = cuda_memset(v2, 0, NL * w2b)'
$t=Rep $t $a ($a+@'

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
'@) 'shadow buffers'
# 3. update-loop offsets
$a='            uo2: "i64" = ll * w2b'
$t=Rep $t $a ($a+"`n            so3: `"i64`" = ll * (3 * H * H * 2)`n            soh: `"i64`" = ll * (H * H * 2)`n            sof: `"i64`" = ll * (H * F * 2)") 'update offsets'
# 4. adamw call sites
$calls=@(
 @('rc = adamw_update(afn, read_i64(AWq, ll * 8), gqd, mq + uo, vq + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWq, ll * 8), gqd, mq + uo, vq + uo, shQKV + so3, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWk, ll * 8), gkd, mk + uo, vk + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWk, ll * 8), gkd, mk + uo, vk + uo, shQKV + so3 + H * H * 2, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWv, ll * 8), gvd, mv + uo, vv + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWv, ll * 8), gvd, mv + uo, vv + uo, shQKV + so3 + 2 * H * H * 2, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AWo, ll * 8), god, mo + uo, vo + uo, H * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AWo, ll * 8), god, mo + uo, vo + uo, shO + soh, zz64, H * H, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AW1, ll * 8), g1d, m1 + uo1, v1 + uo1, H * F, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AW1, ll * 8), g1d, m1 + uo1, v1 + uo1, sh1 + sof, zz64, H * F, lr, ac1, ac2, wd)'),
 @('rc = adamw_update(afn, read_i64(AW2, ll * 8), g2d, m2 + uo2, v2 + uo2, F * H, lr, ac1, ac2, wd)','rc = adamw_update(afn, read_i64(AW2, ll * 8), g2d, m2 + uo2, v2 + uo2, sh2 + sof, sh2T + sof, F * H, lr, ac1, ac2, wd)')
)
foreach($c in $calls){ $t=Rep $t $c[0] $c[1] ('adamw '+$c[0].Substring(20,18)) }
# 5. split forward/backward
$split='        # logits + loss tu OUT cua lop cuoi'
$parts=$t.Split(@($split),[System.StringSplitOptions]::None)
$fwd=$parts[0]; $bwd=$parts[1]
# forward shadow pointers
$a='            ad = read_i64(AA, ll * 8)'
$fwd=Rep $fwd $a ($a+@'

            sfq: "i64" = shQKV + ll * (3 * H * H * 2)
            sfk: "i64" = sfq + H * H * 2
            sfv: "i64" = sfq + 2 * H * H * 2
            sfo: "i64" = shO + ll * (H * H * 2)
            sf1: "i64" = sh1 + ll * (H * F * 2)
            sf2: "i64" = sh2 + ll * (H * F * 2)
'@) 'fwd shadow ptrs'
$fwd=Rep $fwd '            rc = toh3(th3, wqd, wkd, wvd, fpQKV, H * H)' '' 'fwd toh3'
$fwd=Rep $fwd 'one, fpA, T, fpQKV, H, zero, qd, T)' 'one, fpA, T, sfq, H, zero, qd, T)' 'fwd qkv gemm'
$fwd=Rep $fwd "            rc = toh(th, wod, fpB, sHH)`n            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, dO, T)" '            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, sfo, H, zero, dO, T)' 'fwd wo'
$fwd=Rep $fwd "            rc = toh(th, w1d, fpB, H * F)`n            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, fpB, H, zero, zd, T)" '            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, sf1, H, zero, zd, T)' 'fwd w1'
$fwd=Rep $fwd "            rc = toh(th, w2d, fpB, sFH)`n            rc = gemm16(ch, 0, 0, T, H, F, one, fpA, T, fpB, F, zero, dO2, T)" '            rc = gemm16(ch, 0, 0, T, H, F, one, fpA, T, sf2, F, zero, dO2, T)' 'fwd w2'
# backward shadow pointers
$a='            ad = read_i64(AA, ll * 8)'
$bwd=Rep $bwd $a ($a+@'

            sbq: "i64" = shQKV + ll * (3 * H * H * 2)
            sbk: "i64" = sbq + H * H * 2
            sbv: "i64" = sbq + 2 * H * H * 2
            sbo: "i64" = shO + ll * (H * H * 2)
            sb1: "i64" = sh1 + ll * (H * F * 2)
            sb2: "i64" = sh2 + ll * (H * F * 2)
            sb2t: "i64" = sh2T + ll * (H * F * 2)
'@) 'bwd shadow ptrs'
$bwd=Rep $bwd "            rc = toht(tht, w2d, fpT, H * F, F)`n            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, fpT, H, zero, gHH, T)" '            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, sb2t, H, zero, gHH, T)' 'bwd w2t'
$bwd=Rep $bwd "            rc = toh(th, w1d, fpB, H * F)`n            rc = gemm16(ch, 0, 1, T, H, F, one, fpA, T, fpB, H, zero, gY2, T)" '            rc = gemm16(ch, 0, 1, T, H, F, one, fpA, T, sb1, H, zero, gY2, T)' 'bwd w1'
$bwd=Rep $bwd "            rc = toh(th, wod, fpB, sHH)`n            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, zero, gA, T)" '            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, sbo, H, zero, gA, T)' 'bwd wo'
$bwd=Rep $bwd "            rc = toh(th, wqd, fpB, sHH)`n            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, zero, gDX2, T)" '            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, sbq, H, zero, gDX2, T)' 'bwd wq'
$bwd=Rep $bwd "            rc = toh(th, wkd, fpB, sHH)`n            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, one, gDX2, T)" '            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, sbk, H, one, gDX2, T)' 'bwd wk'
$bwd=Rep $bwd "            rc = toh(th, wvd, fpB, sHH)`n            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, one, gDX2, T)" '            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, sbv, H, one, gDX2, T)' 'bwd wv'
Set-Content $p -Value ($fwd+$split+$bwd) -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 8
