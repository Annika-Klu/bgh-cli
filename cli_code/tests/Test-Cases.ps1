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
        Write-Host ("Running test '{0}' for command {1}" -f $testName, $CommandName) -ForegroundColor Gray

        try {
            # no console outputs
            & "$PSScriptRoot\..\$mainCommand.ps1" $CommandName @arguments *>$null 2>&1

            # only suppress stout, errs visible:
            # & "$PSScriptRoot\..\bgh.ps1" $CommandName @arguments >$null
            
            $actualExitCode = $LASTEXITCODE

            if ($actualExitCode -ne $expectedExitCode) {
                Write-Host ("Fehler: erwarteter ExitCode {0}, tatsächlich {1}" -f $expectedExitCode, $actualExitCode) -ForegroundColor Red
                $failed++
            } else {
                Write-Host "Test erfolgreich" -ForegroundColor Green
                $passed++
            }

        } catch {
            Write-Host ("Exception beim Test {0}: {1}" -f $testName, $_) -ForegroundColor Red
            $failed++
        }
    }
   return ($passed, $failed)
}