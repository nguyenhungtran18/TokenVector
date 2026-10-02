# Script tu dong dong goi TokenVector thanh file .nupkg cho NuGet.org
$ErrorActionPreference = "Stop"
$nugetRoot = $PSScriptRoot
$nugetCli = Join-Path $env:TEMP "tkv_pack\nuget.exe"

if (-not (Test-Path $nugetCli)) {
    Write-Host "Dang tai nuget.exe..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path (Split-Path $nugetCli) | Out-Null
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetCli -UseBasicParsing
}

Write-Host "Bat dau dong goi TokenVector NuGet Package..." -ForegroundColor Cyan
& $nugetCli pack (Join-Path $nugetRoot "TokenVector.nuspec") -OutputDirectory $nugetRoot
# PHAI kiem tra exit code TRUOC khi bao SUCCESS. Truoc day khong co buoc nay:
# khi `nuget pack` that bai (vi du NU5019 - file trong nuspec khong ton tai)
# script VAN in "[SUCCESS]" roi chi vao mot .nupkg CU/BI DO ngay truoc - nguoi
# dung tinh la da doi goi xong roi push len nuget.org mot goi cu.
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] nuget pack that bai (exit $LASTEXITCODE) - khong tao duoc .nupkg moi." -ForegroundColor Red
    Write-Host "       File .nupkg cu (neu co) van con nguyen tren dia, KHONG phai ban moi." -ForegroundColor Red
    exit 1
}

$nupkg = Get-ChildItem -Path $nugetRoot -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($nupkg) {
    Write-Host "`n[SUCCESS] Da tao thanh cong package: $($nupkg.FullName)" -ForegroundColor Green
    Write-Host "Kich thuoc: $([math]::Round($nupkg.Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host "`nDe upload len nuget.org, chay lenh sau:" -ForegroundColor Yellow
    Write-Host "nuget push $($nupkg.FullName) -ApiKey <YOUR_NUGET_API_KEY> -Source https://api.nuget.org/v3/index.json" -ForegroundColor White
}
