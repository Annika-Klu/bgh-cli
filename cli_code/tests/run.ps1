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
    $commandName = $parts[1]


    try {
        $testCases = . $file.FullName
        Write-Host ("Running {0} tests for {1}" -f $testCases.Count, $file.Name) -ForegroundColor Cyan
        ($passed, $failed) = Test-Cases -Cases $testCases -CommandName $commandName
        Write-Host ""
        Write-Host ("Finished tests for {0}. Passed: {1}, Failed: {2}" -f $file.Name, $passed, $failed) -ForegroundColor Cyan
        
        $passedTotal += $passed
        $failedTotal += $failed

    } catch {
        Write-Host ("Exception while running test file {0}: {1}" -f $file.Name, $_) -ForegroundColor Red
    }
}

Set-Location $originalLocation

$toalTestsRun = $passedTotal + $failedTotal
Write-Host "$toalTestsRun tests completed. Passed $passedTotal, failed $failedTotal" -ForegroundColor Cyan
