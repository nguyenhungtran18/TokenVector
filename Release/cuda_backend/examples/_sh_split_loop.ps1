$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$t=Get-Content 'ilgpt2_shInitNone.tkv' -Raw
$t=$t.Replace("`r`n","`n")
$old=@'
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
        ll = ll + 1
'@
$n=[regex]::Matches($t,[regex]::Escape($old)).Count
Write-Host ('block hits='+$n)
if($n -ne 1){ throw 'block' }
$new=@'
    ll = 0
    while ll < NL:
        wqd = read_i64(AWq, ll * 8)
        wkd = read_i64(AWk, ll * 8)
        wvd = read_i64(AWv, ll * 8)
        wod = read_i64(AWo, ll * 8)
        w1d = read_i64(AW1, ll * 8)
        w2d = read_i64(AW2, ll * 8)
        ll = ll + 1
    ll = 0
    while ll < NL:
        so3 = ll * (3 * H * H * 2)
        soh = ll * (H * H * 2)
        sof = ll * (H * F * 2)
        ll = ll + 1
'@
$t=$t.Replace($old,$new)
Set-Content 'ilgpt2_shSplitLoop.tkv' -Value $t -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_shSplitLoop.tkv' 'ilgpt2_shSplitLoop.exe' run --emit-il 2>&1 | Select-Object -First 4
