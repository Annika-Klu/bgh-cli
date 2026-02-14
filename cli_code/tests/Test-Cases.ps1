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

    $testNo = 0
    foreach ($testCase in $Cases) {
        Write-Host ""
        $testNo++

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
        Write-Host "$testNo. '$($testName)'" -ForegroundColor White
        try {
            # no console outputs
            #& "$PSScriptRoot\..\$mainCommand.ps1" $CommandName @arguments *>$null 2>&1
            
            $commandParts = $commandName.Split(" ")
            $output = & "$PSScriptRoot\..\bgh.ps1" @CommandParts @arguments *>&1
            $fullOutput = $output -join "`n"
            
            $actualExitCode = $LASTEXITCODE
            $failure = $false
            $failureMessage = ""

            if ($actualExitCode -ne $expectedExitCode) {
                Write-Host ("- Expected exit code {0} but is {1}" -f $expectedExitCode, $actualExitCode) -ForegroundColor Red
                $failure = $true
            } else {
                Write-Host "- Exit code is $expectedExitCode" -ForegroundColor White
            }

            if ($testCase.ContainsKey("ExpectedMessage")) {
                $expectedMsg = [regex]::Escape($testCase.ExpectedMessage)
                if (-not ($fullOutput -match $expectedMsg)) {
                    Write-Host "- Expected message '$($testCase.ExpectedMessage)' not found" -ForegroundColor Red
                    $failure = $true
                } else {
                    Write-Host "- Results in expected message '$($testCase.ExpectedMessage)'" -ForegroundColor White
                }
            }

            if ($failure) {
                $failed++
                Write-Host "❌ Failed" -ForegroundColor Red
            } else {
                Write-Host "✅ Passed" -ForegroundColor Green
                $passed++
            }

        } catch {
            Write-Host ("Exception beim Test {0}: {1}" -f $testName, $_) -ForegroundColor Red
            $failed++
        }
        Write-Host ""
    }
   return ($passed, $failed)
}