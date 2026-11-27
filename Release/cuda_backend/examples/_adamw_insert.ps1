$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
# extern
$a='    {"name": "cuda_h2d", "dll": "cudart.dll", "symbol": "cudaMemcpy",
     "convention": "cdecl", "params": ["i64", "i64", "i64", "i32"], "returns": "i32"},'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'extern anchor' }
$extern=@'
    {"name": "cuda_memset", "dll": "cudart.dll", "symbol": "cudaMemset",
     "convention": "cdecl", "params": ["i64", "i32", "i64"], "returns": "i32"},
'@
$t=$t.Replace($a,$a+$extern)
# splice functions
$snip=Get-Content '_adamw_snippet.tkv' -Raw
$a='def wrand(i: "i32", j: "i32", s: "f32") -> "f32":'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'wrand anchor' }
$t=$t.Replace($a,$snip+$a)
# replace optimizer init block
$a='    lr: "f32" = 8.0
    sfn: "i64" = sgd_init()
    if sfn == 0:
        print("SGD INIT FAIL")
        return 1'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'lr anchor' }
$new=@'
    afn: "i64" = adamw_init()
    if afn == 0:
        print("ADAMW INIT FAIL")
        return 1
    lr: "f32" = 0.0008
    wd: "f32" = 0.01
    b1t: "f32" = 1.0
    b2t: "f32" = 1.0
    rc = cuda_malloc(cell, NL * whb)
    mq: "i64" = read_i64(cell, 0)
    rc = cuda_memset(mq, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    vq: "i64" = read_i64(cell, 0)
    rc = cuda_memset(vq, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    mk: "i64" = read_i64(cell, 0)
    rc = cuda_memset(mk, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    vk: "i64" = read_i64(cell, 0)
    rc = cuda_memset(vk, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    mv: "i64" = read_i64(cell, 0)
    rc = cuda_memset(mv, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    vv: "i64" = read_i64(cell, 0)
    rc = cuda_memset(vv, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    mo: "i64" = read_i64(cell, 0)
    rc = cuda_memset(mo, 0, NL * whb)
    rc = cuda_malloc(cell, NL * whb)
    vo: "i64" = read_i64(cell, 0)
    rc = cuda_memset(vo, 0, NL * whb)
    rc = cuda_malloc(cell, NL * w1b)
    m1: "i64" = read_i64(cell, 0)
    rc = cuda_memset(m1, 0, NL * w1b)
    rc = cuda_malloc(cell, NL * w1b)
    v1: "i64" = read_i64(cell, 0)
    rc = cuda_memset(v1, 0, NL * w1b)
    rc = cuda_malloc(cell, NL * w2b)
    m2: "i64" = read_i64(cell, 0)
    rc = cuda_memset(m2, 0, NL * w2b)
    rc = cuda_malloc(cell, NL * w2b)
    v2: "i64" = read_i64(cell, 0)
    rc = cuda_memset(v2, 0, NL * w2b)'@
$t=$t.Replace($a,$new)
# bias correction at step start
$a='        tA = time_perf()
        pS = time_perf()'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'tA anchor' }
$t=$t.Replace($a,"        b1t = b1t * 0.9`n        b2t = b2t * 0.999`n        ac1: `"f32`" = 1.0 - b1t`n        ac2: `"f32`" = 1.0 - b2t`n"+$a)
# update calls
$a='        while ll < NL:
            gqd = read_i64(AGq, ll * 8)
            gkd = read_i64(AGk, ll * 8)
            gvd = read_i64(AGv, ll * 8)
            god = read_i64(AGo, ll * 8)
            g1d = read_i64(AG1, ll * 8)
            g2d = read_i64(AG2, ll * 8)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'update loop anchor' }
$add=@'
            uo: "i64" = ll * whb
            uo1: "i64" = ll * w1b
            uo2: "i64" = ll * w2b
'@
$t=$t.Replace($a,$a+"`n"+$add+"`n")
foreach($pair in @(
 @('rc = sgd_update(sfn, read_i64(AWq, ll * 8), gqd, H * H, lr)','rc = adamw_update(afn, read_i64(AWq, ll * 8), gqd, mq + uo, vq + uo, H * H, lr, ac1, ac2, wd)'),
 @('rc = sgd_update(sfn, read_i64(AWk, ll * 8), gkd, H * H, lr)','rc = adamw_update(afn, read_i64(AWk, ll * 8), gkd, mk + uo, vk + uo, H * H, lr, ac1, ac2, wd)'),
 @('rc = sgd_update(sfn, read_i64(AWv, ll * 8), gvd, H * H, lr)','rc = adamw_update(afn, read_i64(AWv, ll * 8), gvd, mv + uo, vv + uo, H * H, lr, ac1, ac2, wd)'),
 @('rc = sgd_update(sfn, read_i64(AWo, ll * 8), god, H * H, lr)','rc = adamw_update(afn, read_i64(AWo, ll * 8), god, mo + uo, vo + uo, H * H, lr, ac1, ac2, wd)'),
 @('rc = sgd_update(sfn, read_i64(AW1, ll * 8), g1d, H * F, lr)','rc = adamw_update(afn, read_i64(AW1, ll * 8), g1d, m1 + uo1, v1 + uo1, H * F, lr, ac1, ac2, wd)'),
 @('rc = sgd_update(sfn, read_i64(AW2, ll * 8), g2d, F * H, lr)','rc = adamw_update(afn, read_i64(AW2, ll * 8), g2d, m2 + uo2, v2 + uo2, F * H, lr, ac1, ac2, wd)')
)){
 $n=[regex]::Matches($t,[regex]::Escape($pair[0])).Count
 Write-Output ('call '+$pair[0].Substring(0,36)+' hits='+$n)
 if($n -ne 1){ throw 'call anchor' }
 $t=$t.Replace($pair[0],$pair[1])
}
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 8
