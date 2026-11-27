$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$snip=Get-Content '_toht_snippet.tkv' -Raw
$a='def wrand(i: "i32", j: "i32", s: "f32") -> "f32":'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'wrand' }
$t=$t.Replace($a,$snip+$a)
$a='    th: "i64" = read_i64(kh, 40)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'th' }
$t=$t.Replace($a,$a+"`n    tht: `"i64`" = toht_init()`n    if tht == 0:`n        print(`"TOHT INIT FAIL`")`n        return 1`n    rc = cuda_malloc(cell, H * F * 2)`n    fpT: `"i64`" = read_i64(cell, 0)")
$a='            rc = toh(th, w2d, fpB, sFH)
            rc = cublas_sgemm(ch, 0, 1, T, F, H, one, gOUT, T, w2d, F, zero, gHH, T)'
if(([regex]::Matches($t,[regex]::Escape($a))).Count -ne 1){ throw 'ghh block' }
$t=$t.Replace($a,"            rc = toht(tht, w2d, fpT, H * F, F)`n            rc = gemm16(ch, 0, 0, T, F, H, one, fpA, T, fpT, H, zero, gHH, T)")
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 6
