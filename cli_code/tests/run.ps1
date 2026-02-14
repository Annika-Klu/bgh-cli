param(
    [string]$TestFilesRoot = "$PSScriptRoot/cases"
)

. "$PSScriptRoot/Test-Cases.ps1"

$originalLocation = Get-Location
$testFiles = Get-ChildItem -Path $TestFilesRoot -Recurse -Filter *.tests.ps1 | Sort-Object Name

if (-not $testFiles) {
    Write-Host "No tests found" -ForegroundColor Yellow
    exit 0
}

$passedTotal = 0
$failedTotal = 0

foreach ($file in $testFiles) {
    $parts = ($file.BaseName -split "\.")
    $commandNameRaw = $parts[1]
    $commandName = ($commandNameRaw -replace "-", " ").Trim()

    try {
        Write-Host "`n--------------------------"
        $testCases = . $file.FullName
        Write-Host ("`nRUNNING TESTS FOR '{0}'" -f $commandName) -ForegroundColor Cyan
        ($passed, $failed) = Test-Cases -Cases $testCases -CommandName $commandName
        
        Write-Host ("`nFINISHED | Passed: {1}, Failed: {2}" -f $commandName, $passed, $failed) -ForegroundColor Cyan
        
        $passedTotal += $passed
        $failedTotal += $failed

    } catch {
        Write-Host ("Exception while running test file {0}: {1}" -f $file.Name, $_) -ForegroundColor Red
    }
}

Set-Location $originalLocation

$toalTestsRun = $passedTotal + $failedTotal

Write-Host "`n--------------------------`n"
Write-Host "$toalTestsRun TESTS COMPLETED.`nPassed $passedTotal, failed $failedTotal" -ForegroundColor Cyan
