$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
# helper
$fn=@'

def nanprobe(tag: "i32", p: "i64", hp: "i64") -> "i32":
    rr: "i32" = cuda_h2d(hp, p, 16, 2)
    print("NANP", tag, read_f32(hp, 0), read_f32(hp, 4), rr)
    return rr

'@
$a='def wrand(i: "i32", j: "i32", s: "f32") -> "f32":'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'wrand' }
$t=$t.Replace($a,$fn+$a)
# host probe buffer
$a='    step: "i32" = 1'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'step' }
$t=$t.Replace($a,"    hNP: `"i64`" = alloc_bytes(16)`n"+$a)
# probes: (line to match after, tag)
$probes=@(
 @('            rc = gemm16(ch, 1, 0, F, H, T, one, fpA, T, fpB, T, zero, g2d, F)',1,'g2d'),
 @('            rc = gemm16(ch, 0, 1, T, F, H, one, fpA, T, fpB, F, zero, gHH, T)',2,'gHH'),
 @('            rc = gelu_bwd(bfn, zd, gHH, gZ, T * F)',3,'gZ'),
 @('            rc = gemm16(ch, 1, 0, H, F, T, one, fpA, T, fpB, T, zero, g1d, H)',4,'g1d'),
 @('            rc = gemm16(ch, 0, 1, T, H, F, one, fpA, T, fpB, H, zero, gY2, T)',5,'gY2'),
 @('            rc = add_k(gadd, gDX2, gOUT, gDX2, T * H)',6,'gDX2'),
 @('            rc = gemm16(ch, 0, 1, T, H, H, one, fpA, T, fpB, H, zero, gA, T)',7,'gA'),
 @('            rc = gemm16(ch, 0, 1, T, T, H, one, fpA, T, fpB, T, zero, gP, T)',8,'gP'),
 @('            rc = sf_bwd(sbk, gP, pd, gS, T)',9,'gS'),
 @('            rc = gemm16(ch, 0, 0, T, H, T, hal, fpA, T, fpB, T, zero, gQ, T)',10,'gQ'),
 @('            rc = gemm16(ch, 1, 0, H, H, T, one, fpA, T, fpB, T, zero, gqd, H)',11,'gqd')
)
foreach($pr in $probes){
    $line=$pr[0]; $tag=$pr[1]; $ptr=$pr[2]
    $n=[regex]::Matches($t,[regex]::Escape($line)).Count
    Write-Output ('probe '+$tag+' hits='+$n)
    if($n -ne 1){ throw ('probe '+$tag) }
    $ins="            if ll == 23:`n                rc = nanprobe($tag, $ptr, hNP)"
    $t=$t.Replace($line,$line+"`n"+$ins)
}
Set-Content 'ilgpt2_nanprobe.tkv' -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_nanprobe.tkv' 'ilgpt2_nanprobe.exe' run --emit-il 2>&1 | Select-Object -First 8
