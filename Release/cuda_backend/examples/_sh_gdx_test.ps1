$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$base=Get-Content 'ilgpt2_writeonly.tkv' -Raw
$base=$base.Replace("`r`n","`n")
# shadow init loop before t0
$a='    t0 = time_perf()'
if(([regex]::Matches($base,[regex]::Escape($a))).Count -ne 1){ throw 't0' }
$init=@'
    ll = 0
    while ll < NL:
        wqd = read_i64(AWq, ll * 8)
        wkd = read_i64(AWk, ll * 8)
        wvd = read_i64(AWv, ll * 8)
        wod = read_i64(AWo, ll * 8)
        w1d = read_i64(AW1, ll * 8)
        w2d = read_i64(AW2, ll * 8)
        so3 = ll * (3 * H * H * 2)
        soh = ll * (H * H * 2)
        sof = ll * (H * F * 2)
        rc = toh3(th3, wqd, wkd, wvd, shQKV + so3, H * H)
        rc = toh(th, wod, shO + soh, sHH)
        rc = toh(th, w1d, sh1 + sof, H * F)
        rc = toh(th, w2d, sh2 + sof, H * F)
        rc = toht(tht, w2d, sh2T + sof, H * F, F)
        ll = ll + 1
'@
$base=$base.Replace($a,$init+"`n"+$a)
# declare shared i64 offset vars (so3/soh/sof already declared in update loop; add early declaration)
$a="`n    qoff: `"i64`" = qb"
if(([regex]::Matches($base,[regex]::Escape($a))).Count -ne 1){ throw 'qoff decl' }
$base=$base.Replace($a,"`n    so3: `"i64`" = 0`n    soh: `"i64`" = 0`n    sof: `"i64`" = 0`n"+$a)
# add backward shadow pointers before pd load (backward part only)
$split='        # logits + loss tu OUT cua lop cuoi'
$parts=$base.Split(@($split),[System.StringSplitOptions]::None)
$fwdp=$parts[0]; $bwdp=$parts[1]
$a='            pd = read_i64(AP, ll * 8)
            zd = read_i64(AZ, ll * 8)'
if(([regex]::Matches($bwdp,[regex]::Escape($a))).Count -ne 1){ throw 'bwd pd' }
$ptrs=@'
            so3 = ll * (3 * H * H * 2)
            sbq: "i64" = shQKV + so3
            sbk: "i64" = sbq + qoff
            sbv: "i64" = sbk + qoff
'@
$bwdp=$bwdp.Replace($a,$ptrs+"`n"+$a)
$base=$fwdp+$split+$bwdp
$targets=@(
 @{tag='B4'; old='            rc = toh(th, wqd, fpB, sHH)'; new='            rc = toh(th, wqd, fpB, sHH)'},
 @{tag='B5'; old='            rc = toh(th, wkd, fpB, sHH)'; new='            rc = toh(th, wkd, fpB, sHH)'},
 @{tag='B6'; old='            rc = toh(th, wvd, fpB, sHH)'; new='            rc = toh(th, wvd, fpB, sHH)'}
)
foreach($t in $targets){
  $s=$base
  # the three weight-toh lines are in gDX2 block; identify by following gemm line
  $lines=@('wqd','wkd','wvd')
  $idx=[array]::IndexOf($lines, $t.tag.Substring(1))
  $var=$lines[$idx]
  $beta='one'
  if($idx -eq 0){ $beta='zero' }
  $old="            rc = toh(th, $var, fpB, sHH)`n            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, $beta, gDX2, T)"
  $n=[regex]::Matches($s,[regex]::Escape($old)).Count
  Write-Host ($t.tag+' target hits='+$n)
  if($n -ne 1){ throw ($t.tag+' target') }
  $ptr='sb'+@{'B4'='q';'B5'='k';'B6'='v'}[$t.tag]
  $new="            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, $ptr, H, one, gDX2, T)"
  $s=$s.Replace($old,$new)
  Set-Content ('ilgpt2_sh'+$t.tag+'.tkv') -Value $s -NoNewline -Encoding UTF8
  & '..\..\dist\tkvc-tv.exe' ('ilgpt2_sh'+$t.tag+'.tkv') ('ilgpt2_sh'+$t.tag+'.exe') run --emit-il 2>&1 | Select-Object -First 3
}
