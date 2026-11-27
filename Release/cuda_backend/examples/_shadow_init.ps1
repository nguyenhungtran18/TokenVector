$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
$t=$t.Replace("`r`n","`n")
$a='    t0 = time_perf()'
$n=[regex]::Matches($t,[regex]::Escape($a)).Count
Write-Host ('anchor hits='+$n)
if($n -ne 1){ throw 't0' }
$init=@'
    ll = 0
    while ll < NL:
        wqd = read_i64(AWq, ll * 8)
        wkd = read_i64(AWk, ll * 8)
        wvd = read_i64(AWv, ll * 8)
        wod = read_i64(AWo, ll * 8)
        w1d = read_i64(AW1, ll * 8)
        w2d = read_i64(AW2, ll * 8)
        rc = toh3(th3, wqd, wkd, wvd, shQKV + ll * (3 * H * H * 2), H * H)
        rc = toh(th, wod, shO + ll * (H * H * 2), sHH)
        rc = toh(th, w1d, sh1 + ll * (H * F * 2), H * F)
        rc = toh(th, w2d, sh2 + ll * (H * F * 2), H * F)
        rc = toht(tht, w2d, sh2T + ll * (H * F * 2), H * F, F)
        ll = ll + 1
'@
$t=$t.Replace($a,$init+"`n"+$a)
Set-Content $p -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' $p 'ilgpt2_trainN_clean.exe' run --emit-il 2>&1 | Select-Object -First 5
