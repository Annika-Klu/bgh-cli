param(
    [string]$TestFilesRoot,
    [switch]$WriteOutput
)

. "$PSScriptRoot/installer.ps1"
. "$PSScriptRoot/Test-Commands.ps1"

$originalLocation = Get-Location

try {
    # Dummy logic. To do: encapsulate installer.template logic as func and
    # invoke directly in tests/run.ps1 with test params for install path etc.
    $source = "$PSScriptRoot\..\cli_code"
    $TestRoot = Join-Path $originalLocation ".sandbox"
    Write-Host $TestRoot
    Install-CLI -InstallPath $TestRoot
} catch {
    Write-Host "Installer script failed: $($_)" -ForegroundColor Red
    exit 1
}

$TestFilesRoot = Join-Path $originalLocation "commands"
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
        ($passed, $failed) = Test-Commands -TestRoot $TestRoot -Cases $testCases -CommandName $commandName -WriteOutput $WriteOutput
        
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

if ($failedTotal -gt 0) { exit 1 }