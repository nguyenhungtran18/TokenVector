$ErrorActionPreference='Stop'
cd 'D:\TokenVector.CudaBackend\Release\cuda_backend\examples'
$p='ilgpt2_trainN_clean.tkv'
$t=Get-Content $p -Raw
foreach($tag in @('B1 dW2','B2 dZ','B3 ln2','B4 attn','B5 dS','B6 qkv','MARK B')){
    $pat='(?m)^\s*print\("'+[regex]::Escape($tag)+'", ll\)\r?\n'
    $n=[regex]::Matches($t,$pat).Count
    Write-Output ($tag+' hits='+$n)
    $t=[regex]::Replace($t,$pat,'')
}
Set-Content $p -Value $t -NoNewline -Encoding UTF8
$n2=[regex]::Matches($t,'print\(').Count
Write-Output ('prints left='+$n2)
& '..\..\dist\tkvc-tv.exe' $p ilgpt2_trainN_clean.exe run --emit-il 2>&1 | Select-Object -First 4
