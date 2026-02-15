function Check-FailedOutputs {
    param(
        [Array]$ExpectedOutputs,
        [string]$FullOutput
    )

    $someFailed = $false
    foreach($output in $ExpectedOutputs) {
        $expectedMsg = [regex]::Escape($output)
        if (-not ($FullOutput -match $expectedMsg)) {
            Write-Host ("- Output '{0}' not found" -f $output) -ForegroundColor Red
            $someFailed = $true
        } else {
            Write-Host ("- Output contains '{0}'" -f $output) -ForegroundColor White
        }
    }
    return $someFailed
}

function Test-Commands {
    param(
        [Parameter(Mandatory)]
        [string]$TestRoot,

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

            $output = & "$TestRoot\bgh.ps1" @commandParts @arguments *>&1
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

            if ($testCase.ContainsKey("ExpectedOutputs") -and $testCase.ExpectedOutputs) {
                $failedOutputs = Check-FailedOutputs -ExpectedOutputs $testCase.ExpectedOutputs -FullOutput $fullOutput
                if (-not $failure) { $failure = ($failedOutputs -gt 0) }
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