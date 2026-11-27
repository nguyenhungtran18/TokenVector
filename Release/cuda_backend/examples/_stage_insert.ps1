$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_trainN_clean.tkv' -Raw
$reps=@(
 @('        tA = time_perf()', "        tA = time_perf()`n        pS = time_perf()"),
 @('        tH = time_perf()', "        ssy = cuda_sync()`n        pS2 = time_perf()`n        print(`"SG FWD`", (pS2 - pS) * 500.0)`n        tH = time_perf()"),
 @('        tB = time_perf()', "        ssy = cuda_sync()`n        pS3 = time_perf()`n        print(`"SG HEAD`", (pS3 - pS2) * 500.0)`n        tB = time_perf()"),
 @('        tC = time_perf()', "        ssy = cuda_sync()`n        pS4 = time_perf()`n        print(`"SG BWD`", (pS4 - pS3) * 500.0)`n        tC = time_perf()"),
 @('        step = step + 1', "        ssy = cuda_sync()`n        pS5 = time_perf()`n        print(`"SG UPD`", (pS5 - pS4) * 500.0)`n        step = step + 1")
)
foreach($r in $reps){
    $n=[regex]::Matches($src,[regex]::Escape($r[0])).Count
    Write-Output ('anchor '+$r[0].Trim()+' hits='+$n)
    if($n -ne 1){ exit 1 }
    $src=$src.Replace($r[0],$r[1])
}
$a2='    thd: "f64" = 0.0'
$src=$src.Replace($a2,$a2+"`n    pS: `"f64`" = 0.0`n    pS2: `"f64`" = 0.0`n    pS3: `"f64`" = 0.0`n    pS4: `"f64`" = 0.0`n    pS5: `"f64`" = 0.0")
Set-Content 'ilgpt2_stages.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_stages.tkv' 'ilgpt2_stages.exe' run --emit-il 2>&1 | Select-Object -First 5
$il=Get-Content 'ilgpt2_stages.il' -Raw
$m=[regex]::Matches($il,'stloc\.s (\d+)')|ForEach-Object{[int]$_.Groups[1].Value}
Write-Output ('max_stloc='+($m|Measure-Object -Maximum|Select-Object -ExpandProperty Maximum))
