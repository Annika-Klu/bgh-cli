function Get-HostInput {
    param(
        [string]$Name,
        [string]$Prompt,
        [string]$Default = ""
    )

    if ($CLI_TESTMODE) {
        Write-Host "In test mode, checking for '$Name' in CLI_HOSTINPUTS..." -ForegroundColor Cyan
        if ($CLI_HOSTINPUTS.PSObject.Properties.Match($Name)) {
            Write-Host "Found input for '$Name': $($CLI_HOSTINPUTS.$Name)" -ForegroundColor Green
            return $CLI_HOSTINPUTS.$Name
        }
        Write-Host "No input found for '$Name'. Returning default: $Default" -ForegroundColor Yellow
        return $Default
    } else {
        return Read-Host $Prompt
    }
}

function Get-YesOrNo {
    param (
        [Parameter(Mandatory=$true)]
        [String]$Message
    )

    $validResponses = @{
        "j" = $true
        "n" = $false
    }

    $response = ""
    $responseIsValid = $false

    do {
        $response = Get-HostInput -Name "YesOrNo" -Prompt "$Message (j/n)" -Default "n"
        $responseIsValid = $validResponses.ContainsKey($response)
        if (-not $responseIsValid) {
            Out-Message "Ungültige Eingabe, bitte 'j' oder 'n' angeben." -Type "error"
        }
    } until ($responseIsValid)

    return $validResponses[$response]
}

function Test-UserInput {
    param(
        [String]$Name,
        [String]$Value,
        [String]$Type,
        [Array]$ValidValues = @()
    )

    try {
        switch ($Type.ToLower()) {
            'int' {
                $convertedValue = [int]$Value
                break
            }
            'double' {
                $convertedValue = [double]$Value
                break
            }
            'boolean' {
                $convertedValue = [bool]$Value
                break
            }
            'datetime' {
                $convertedValue = [datetime]$Value
                break
            }
            default {
                $convertedValue = $Value
            }
        }
    } catch {
        throw "Der Wert '$Value' für '$Name' konnte nicht in den Typ '$Type' konvertiert werden."
    }

    if ($ValidValues.Count -gt 0) {
        if ($ValidValues -notcontains $convertedValue) {
            throw "Ungültiger Wert '$Value' für '$Name'. Erlaubte Werte sind: $($ValidValues -join ', ')"
        }
    }

    return $convertedValue
}
