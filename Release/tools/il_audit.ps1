# il_audit.ps1 - kiem tra IL do compiler sinh cho trung/thua.
# Dung:
#   powershell -File tools\il_audit.ps1 -Path build\selfhost\g2.il
#   powershell -File tools\il_audit.ps1 -Path build\selfhost\g2.il -ReportUnused
#   powershell -File tools\il_audit.ps1 -Path build\selfhost\g2.il -FailOnDuplicate
#
# Quy uoc:
#   - Duplicate method TRONG CUNG MOT CLASS = LOI (assembly khong hop le).
#   - Duplicate class = LOI.
#   - "Unused candidates" chi la BAO CAO, KHONG fail gate (reflection/extern/interface
#     can gia dương tinh neu ep theo call-graph may moc).
[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot '..\build\selfhost\g2.il'),
    [switch]$ReportUnused,
    [switch]$FailOnDuplicate,
    [switch]$FailOnDuplicateClass
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
    throw "Khong tim thay IL file: $Path"
}

$lines = Get-Content -LiteralPath $Path

$classCount = 0
$methodCount = 0
$lineCount = $lines.Count
$maxstack8 = 0
$pinvokes = 0
$ldstr = 0
$newobj = 0
$duplicates = New-Object System.Collections.Generic.List[string]
$classesSeen = @{}
$membersByClass = @{}
$currentClass = $null
$allDefined = New-Object System.Collections.Generic.List[string]
$definitionCounts = @{}
$useCounts = @{}

function Get-ClassKey([string]$line) {
    $parts = ($line.Trim() -split '\s+')
    $keywords = @('public','private','nested','ansi','auto','sequential','sealed','abstract','beforefieldinit','interface')
    for ($i = 1; $i -lt $parts.Length; $i++) {
        $t = $parts[$i].Trim()
        if ($keywords -notcontains $t) { return $t }
    }
    return $null
}

function Get-MethodName([string]$line) {
    $m = [regex]::Match($line, '^\s*\.method\s+.*?\s([^\s\(]+)\s*\(')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Get-ClassMethodRef([string]$line) {
    $m = [regex]::Match($line, '([A-Za-z_][A-Za-z0-9_]+)::([A-Za-z_][A-Za-z0-9_]+)')
    if ($m.Success) { return ($m.Groups[1].Value + '::' + $m.Groups[2].Value) }
    return $null
}

foreach ($line in $lines) {
    $t = $line.Trim()
    if ($t -match '^\.class\b') {
        $classCount += 1
        $key = Get-ClassKey $line
        if ($null -eq $key) { $key = '<unknown-class>' }
        if (-not $membersByClass.ContainsKey($key)) { $membersByClass[$key] = @{} }
        $currentClass = $key
        if ($classesSeen.ContainsKey($key)) {
            $duplicates.Add("duplicate class: $key")
        } else {
            $classesSeen[$key] = $true
        }
        continue
    }
    if ($t -match '^\.method\b') {
        $methodCount += 1
        $sig = $t
        if ($t -match 'pinvokeimpl') { $pinvokes += 1 }
        if ($t -match '\.maxstack\s+8') { $maxstack8 += 1 }
        if (-not $membersByClass.ContainsKey($currentClass)) { $membersByClass[$currentClass] = @{} }
        $members = $membersByClass[$currentClass]
        if ($members.ContainsKey($sig)) {
            $duplicates.Add("duplicate method in ${currentClass}: $sig")
        } else {
            $members[$sig] = $true
        }
        $name = Get-MethodName $line
        if ($null -ne $name) {
            $key = "$currentClass::$name"
            $allDefined.Add($key) | Out-Null
            $definitionCounts[$key] = 1
        }
        continue
    }
    if ($t -match 'ldstr\b') { $ldstr += 1 }
    if ($t -match 'newobj\b') { $newobj += 1 }

    foreach ($m in [regex]::Matches($line, '([A-Za-z_][A-Za-z0-9_]+)::([A-Za-z_][A-Za-z0-9_]+)')) {
        $key = $m.Groups[1].Value + '::' + $m.Groups[2].Value
        if (-not $useCounts.ContainsKey($key)) { $useCounts[$key] = 0 }
        $useCounts[$key] += 1
    }
}

$duplicateClass = @($duplicates | Where-Object { $_ -like 'duplicate class:*' })
$duplicateMethod = @($duplicates | Where-Object { $_ -like 'duplicate method in *' })

Write-Host "IL audit: $Path"
Write-Host "lines:                 $lineCount"
Write-Host "classes:               $classCount"
Write-Host "methods:               $methodCount"
Write-Host "pinvokeimpl:           $pinvokes"
Write-Host ".maxstack 8:           $maxstack8"
Write-Host "ldstr:                 $ldstr"
Write-Host "newobj:                $newobj"
Write-Host "duplicate classes:     $($duplicateClass.Count)"
Write-Host "duplicate methods:     $($duplicateMethod.Count)"

if ($duplicateClass.Count -gt 0) {
    Write-Host ""
    Write-Host "Duplicate classes:"
    $duplicateClass | ForEach-Object { Write-Host "  $_" }
}
if ($duplicateMethod.Count -gt 0) {
    Write-Host ""
    Write-Host "Duplicate methods:"
    $duplicateMethod | ForEach-Object { Write-Host "  $_" }
}

if ($ReportUnused) {
    Write-Host ""
    Write-Host "Unused static method candidates (heuristic; reflection/interface may cause false positives):"
    $candidates = 0
    foreach ($key in ($definitionCounts.Keys | Sort-Object)) {
        $use = 0
        if ($useCounts.ContainsKey($key)) { $use = $useCounts[$key] }
        if ($use -le 1) {
            $candidates += 1
            Write-Host "  $key"
            if ($candidates -ge 40) {
                Write-Host "  ... more (cap 40)"
                break
            }
        }
    }
    if ($candidates -eq 0) { Write-Host "  none" }
}

$failed = $false
if ($FailOnDuplicateClass -and $duplicateClass.Count -gt 0) { $failed = $true }
if ($FailOnDuplicate -and $duplicateMethod.Count -gt 0) { $failed = $true }

if ($failed) {
    throw "IL audit FAILED: duplicate class or method detected"
}
