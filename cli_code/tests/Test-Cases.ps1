function Test-Cases {
    param(
        [Parameter(Mandatory)]
        [Array]$Cases,

        [Parameter(Mandatory)]
        [string]$CommandName
    )

    $mainCommand = "bgh"
    $passed = 0
    $failed = 0

    foreach ($testCase in $Cases) {

        $arguments = @()
        $expectedExitCode = if ($testCase.ContainsKey("ExpectedExitCode")) { $testCase.ExpectedExitCode } else { 0 }

        if ($testCase.ContainsKey("Arguments") -and $testCase.Arguments) {
            foreach ($key in $testCase.Arguments.Keys) {
                $value = $testCase.Arguments[$key]
                if ($value -is [bool] -and $value) {
                    $arguments += "-$key"
                } else {
                    $arguments += "-$key"
                    $arguments += $value
                }
            }
        }

        $testName = if ($testCase.ContainsKey("Name")) { $testCase.Name } else { "(unnamed test)" }
        Write-Host ("Test '{0}'" -f $testName) -ForegroundColor White

        try {
            # no console outputs
            #& "$PSScriptRoot\..\$mainCommand.ps1" $CommandName @arguments *>$null 2>&1
            
            $output = & "$PSScriptRoot\..\bgh.ps1" $CommandName @arguments *>&1
            $fullOutput = $output -join "`n"
            
            $actualExitCode = $LASTEXITCODE
            $failure = $false
            $failureMessage = ""

            if ($actualExitCode -ne $expectedExitCode) {
                $failureMessage = ("Expected exit code {0} but is {1}" -f $expectedExitCode, $actualExitCode)
                $failure = $true
            }

            if ($testCase.ContainsKey("ExpectedErrorMessage")) {
                $expectedMsg = [regex]::Escape($testCase.ExpectedErrorMessage)
                if (-not ($fullOutput -match $expectedMsg)) {
                    $failureMessage = "Expected error message '$($testCase.ExpectedErrorMessage)' not found"
                    $failure = $true
                }
            }

            if ($failure) {
                $failed++
                Write-Host $failureMessage -ForegroundColor Red
            } else {
                Write-Host "Success" -ForegroundColor Green
                $passed++
            }

        } catch {
            Write-Host ("Exception beim Test {0}: {1}" -f $testName, $_) -ForegroundColor Red
            $failed++
        }
    }
   return ($passed, $failed)
}