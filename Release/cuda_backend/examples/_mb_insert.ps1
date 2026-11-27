$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_trainN_clean.tkv' -Raw
$anchor='    step: "i32" = 1'
$n=[regex]::Matches($src,[regex]::Escape($anchor)).Count
Write-Output ('anchor hits='+$n)
if($n -ne 1){ exit 1 }
$bench=@'
    mb0: "f64" = 0.0
    mb1: "f64" = 0.0
    mk: "i32" = 0
    mb0 = time_perf()
    mk = 0
    while mk < 2000:
        mptr = alloc_bytes(8)
        mk = mk + 1
    mb1 = time_perf()
    print("MB alloc8_us", (mb1 - mb0) * 500.0)
    mb0 = time_perf()
    mk = 0
    while mk < 2000:
        mptr = alloc_bytes(56)
        mk = mk + 1
    mb1 = time_perf()
    print("MB alloc56_us", (mb1 - mb0) * 500.0)
    mb0 = time_perf()
    mk = 0
    while mk < 1000:
        wh = write_i64(mptr, 0, dOUT)
        mk = mk + 1
    mb1 = time_perf()
    print("MB writei64_us", (mb1 - mb0) * 1000.0)
    mb0 = time_perf()
    mk = 0
    while mk < 1000:
        rc = toh(th, dOUT, fpA, 4)
        mk = mk + 1
    ssy = cuda_sync()
    mb1 = time_perf()
    print("MB tohcall_us", (mb1 - mb0) * 1000.0)
    mb0 = time_perf()
    mk = 0
    while mk < 1000:
        rc = gemm16(ch, 0, 0, H, H, H, one, fpA, H, fpB, H, zero, dQ, H)
        mk = mk + 1
    ssy = cuda_sync()
    mb1 = time_perf()
    print("MB cublascall_us", (mb1 - mb0) * 1000.0)

'@
$src=$src.Replace($anchor,$bench+$anchor)
Set-Content 'ilgpt2_mb.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_mb.tkv' 'ilgpt2_mb.exe' run --emit-il 2>&1 | Select-Object -First 5
$il=Get-Content 'ilgpt2_mb.il' -Raw
$m=[regex]::Matches($il,'stloc\.s (\d+)')|ForEach-Object{[int]$_.Groups[1].Value}
Write-Output ('max_stloc='+($m|Measure-Object -Maximum|Select-Object -ExpandProperty Maximum))
