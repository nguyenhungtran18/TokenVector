$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$src=Get-Content 'ilgpt2_trainN_clean.tkv' -Raw
$n1=[regex]::Matches($src,[regex]::Escape('    while step <= 2:')).Count
$n2=[regex]::Matches($src,[regex]::Escape('    print("MS_STEP", (dtm * 1000.0) / 2.0)')).Count
Write-Output ('loop hits='+$n1+' msstep hits='+$n2)
if($n1 -ne 1 -or $n2 -ne 1){ exit 1 }
$src=$src.Replace('    while step <= 2:','    while step <= 10:')
$src=$src.Replace('    print("MS_STEP", (dtm * 1000.0) / 2.0)','    print("MS_STEP", (dtm * 1000.0) / 10.0)')
$anchor='        step = step + 1'
$src=$src.Replace($anchor,"        print(`"STEPMS`", (time_perf() - tA) * 1000.0)`n"+$anchor)
Set-Content 'ilgpt2_long.tkv' -Value $src -NoNewline -Encoding UTF8
& '..\..\dist\tkvc-tv.exe' 'ilgpt2_long.tkv' 'ilgpt2_long.exe' run --emit-il 2>&1 | Select-Object -First 5
$il=Get-Content 'ilgpt2_long.il' -Raw
$m=[regex]::Matches($il,'stloc\.s (\d+)')|ForEach-Object{[int]$_.Groups[1].Value}
Write-Output ('max_stloc='+($m|Measure-Object -Maximum|Select-Object -ExpandProperty Maximum))
