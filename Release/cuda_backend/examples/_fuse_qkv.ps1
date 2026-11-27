$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$snip=Get-Content '_toh3_snippet.tkv' -Raw
$a='def wrand(i: "i32", j: "i32", s: "f32") -> "f32":'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'wrand' }
$t=$t.Replace($a,$snip+$a)
# init th3 + fpQKV after tht block
$a='    fpT: "i64" = read_i64(cell, 0)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'fpT' }
$t=$t.Replace($a,$a+@'

    th3: "i64" = toh3_init()
    if th3 == 0:
        print("TOH3 INIT FAIL")
        return 1
    rc = cuda_malloc(cell, 3 * H * H * 2)
    fpQKV: "i64" = read_i64(cell, 0)
'@)
# AQ allocation 3x, drop AK/AV device allocation
$a='        rc = cuda_malloc(cell, qb)
        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AK, ll * 8, read_i64(cell, 0))
        rc = cuda_malloc(cell, qb)
        wh = write_i64(AV, ll * 8, read_i64(cell, 0))'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'AQ alloc' }
$t=$t.Replace($a,'        rc = cuda_malloc(cell, 3 * qb)
        wh = write_i64(AQ, ll * 8, read_i64(cell, 0))')
# pointer loads: both loops
$a='            qd = read_i64(AQ, ll * 8)
            kd = read_i64(AK, ll * 8)
            vd = read_i64(AV, ll * 8)'
$n=[regex]::Matches($t,[regex]::Escape($a)).Count
Write-Output ('pointer blocks='+$n)
if($n -ne 2){ throw 'pointer loads' }
$t=$t.Replace($a,"            qd = read_i64(AQ, ll * 8)`n            qoff: `"i64`" = qb`n            kd = qd + qoff`n            vd = kd + qoff")
# forward QKV -> one fused GEMM
$a='            rc = toh(th, y1d, fpA, sQH)
            rc = toh(th, wqd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, qd, T)
            if rc != 0:
                print("Q GEMM FAIL", ll, rc)
                return 1
            rc = toh(th, wkd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, kd, T)
            if rc != 0:
                print("K GEMM FAIL", ll, rc)
                return 1
            rc = toh(th, wvd, fpB, sHH)
            rc = gemm16(ch, 0, 0, T, H, H, one, fpA, T, fpB, H, zero, vd, T)
            if rc != 0:
                print("V GEMM FAIL", ll, rc)
                return 1'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'fwd qkv' }
$t=$t.Replace($a,"            rc = toh(th, y1d, fpA, sQH)`n            rc = toh3(th3, wqd, wkd, wvd, fpQKV, H * H)`n            rc = gemm16(ch, 0, 0, T, 3 * H, H, one, fpA, T, fpQKV, H, zero, qd, T)`n            if rc != 0:`n                print(`"QKV GEMM FAIL`", ll, rc)`n                return 1")
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
