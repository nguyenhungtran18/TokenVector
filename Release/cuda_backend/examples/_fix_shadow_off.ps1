$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
function Rep2($s,$old,$new,$tag){
  $n=[regex]::Matches($s,[regex]::Escape($old)).Count
  Write-Host ($tag+' hits='+$n)
  if($n -lt 1){ throw $tag }
  return $s.Replace($old,$new)
}
# declare shared i64 offsets once after zz64
$t=Rep2 $t '    zz64: "i64" = 0' @'
    zz64: "i64" = 0
    qoff: "i64" = qb
    so3: "i64" = 0
    soh: "i64" = 0
    sof: "i64" = 0
'@ 'declare offsets'
# remove typed redeclarations in loops
$t=Rep2 $t '            qoff: "i64" = qb' '' 'qoff redecl'
$t=Rep2 $t '            so3: "i64" = ll * (3 * H * H * 2)' '            so3 = ll * (3 * H * H * 2)' 'so3 decl'
$t=Rep2 $t '            soh: "i64" = ll * (H * H * 2)' '            soh = ll * (H * H * 2)' 'soh decl'
$t=Rep2 $t '            sof: "i64" = ll * (H * F * 2)' '            sof = ll * (H * F * 2)' 'sof decl'
# i64 offsets in init loop
$a='        w2d = read_i64(AW2, ll * 8)'
$t=Rep2 $t $a ($a+"`n        so3 = ll * (3 * H * H * 2)`n        soh = ll * (H * H * 2)`n        sof = ll * (H * F * 2)") 'init offsets'
$t=Rep2 $t 'shQKV + ll * (3 * H * H * 2)' 'shQKV + so3' 'init qkv'
$t=Rep2 $t 'shO + ll * (H * H * 2)' 'shO + soh' 'init o'
$t=Rep2 $t 'sh1 + ll * (H * F * 2)' 'sh1 + sof' 'init w1'
$t=Rep2 $t 'sh2 + ll * (H * F * 2)' 'sh2 + sof' 'init w2'
$t=Rep2 $t 'sh2T + ll * (H * F * 2)' 'sh2T + sof' 'init w2t'
# replace i32 offsets with i64 qoff everywhere
$t=Rep2 $t '+ H * H * 2' '+ qoff' 'hh2'
$t=Rep2 $t '+ 2 * H * H * 2' '+ qoff + qoff' 'hh4'
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
