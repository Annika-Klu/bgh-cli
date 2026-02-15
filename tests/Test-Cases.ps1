function Test-Cases {
    param(
        [Parameter(Mandatory)]
        [Array]$Cases,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [boolean]$WriteOutput
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
                $arguments += "$key=$value"
            }
        }

        if ($testCase.ContainsKey("Flags") -and $testCase.Flags) {
            $arguments += $testCase.Flags
        }

        $arguments += "TESTMODE"

        if ($testCase.ContainsKey("HostInputs")) {
            $hostInputsJson = ($testCase.HostInputs | ConvertTo-Json -Compress)
            $arguments += "HOSTINPUTS=$hostInputsJson"
        }

        $testName = if ($testCase.ContainsKey("Name")) { $testCase.Name } else { "(unnamed test)" }
        Write-Host "$testNo. '$($testName)'" -ForegroundColor White

        try {
            $commandParts = $CommandName.Trim().Split(" ")

            $output = & "$PSScriptRoot\..\cli_code\bgh.ps1" @commandParts @arguments *>&1
            $fullOutput = $output -join "`n"
            if ($WriteOutput) { Write-Host $fullOutput }

            $actualExitCode = $LASTEXITCODE

            $failure = $false

            if ($actualExitCode -ne $expectedExitCode) {
                Write-Host ("- Expected exit code {0} but got {1}" -f $expectedExitCode, $actualExitCode) -ForegroundColor Red
                $failure = $true
            } else {
                Write-Host "- Exit code is $expectedExitCode" -ForegroundColor White
            }

            if ($testCase.ContainsKey("ExpectedMessage") -and $testCase.ExpectedMessage) {
                $expectedMsg = [regex]::Escape($testCase.ExpectedMessage)
                if (-not ($fullOutput -match $expectedMsg)) {
                    Write-Host ("- Expected message '{0}' not found" -f $testCase.ExpectedMessage) -ForegroundColor Red
                    $failure = $true
                } else {
                    Write-Host ("- Expected message '{0}'" -f $testCase.ExpectedMessage) -ForegroundColor White
                }
            }

            if ($failure) {
                $failed++
                Write-Host "❌ Failed" -ForegroundColor Red
            } else {
                $passed++
                Write-Host "✅ Passed" -ForegroundColor Green
            }

        } catch {
            Write-Host ("Exception in test '{0}': {1}" -f $testName, $_) -ForegroundColor Red
            $failed++
        }
    }

    return ($passed, $failed)
}