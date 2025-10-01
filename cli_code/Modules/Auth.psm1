Import-Module "$PSScriptRoot\DotEnv.psm1"

function Set-ApiUrl {
    do {
        $subdomain = $CT_SUBDOMAIN
        if (-not $subdomain) {
            $subdomain = Read-Host "Welche Subdomain hat deine Gemeinde? (z. B. bei 'https://beispielgemeinde.church.tools' gib ein 'beispielgemeinde'.)"
        }
        $churchUrl = "https://$subdomain.church.tools"

        $errorMsg = "Ungültige Eingabe: '$subdomain.church.tools' existiert nicht."

        try {
            $response = Invoke-WebRequest -Uri $churchUrl -TimeoutSec 5 -ErrorAction Stop
            $body = $response.Content
            if ($body -match "Finde deine Gemeinde") {
                Out-Message $errorMsg error
                $isValid = $false
            } else {
                Out-Message "Anmelden bei: $churchUrl"
                $isValid = $true
            }
        } catch {
            Out-Message $errorMsg error
            $isValid = $false
        }

    } until ($isValid)
    return "$churchUrl/api"
}

function Save-ApiToken {
    param(
        [string]$ApiUrl
    )
    do {
        try {
            $pastedToken = Read-Host "Bitte gib dein Login-Token ein"
            Save-EncryptedToken -Token $pastedToken -Path (Join-Path $PWD "ctlogintoken.sec")
            $isValid = $true
        } catch {
            Out-Message "Das Token ist ungültig. $_" error
            $isValid = $false
        }
    } until ($isValid)
}

function Set-OutDir {
    $suggestedOutDir = "$($env:USERPROFILE)\Documents"
    do {
        $selectedOutDir = Read-Host "Wo sollen heruntergeladene oder generierte Dateien gespeichert werden? (Ohne Eingabe bestätigen für '$suggestedOutDir')"
        if (-not $selectedOutDir) {
            return $suggestedOutDir
        }
        if (Test-Path $selectedOutDir) {
            $isValid = $true
        } else {
            Out-Message "Ungültiger Pfad." error
            $isValid = $false
        }
    } until ($isValid)
    return $selectedOutDir
}

$initialSetupInfo = @"
Für die Ersteinrichtung brauchst du dein Churchtools-Login-Token. Um es zu finden, 
- suche in Churchtools unter 'Personen' deinen eigenen Datensatz und klicke ihn an.
- Klicke auf 'Berechtigungen'. 
- Im dann angezeigten Fenseter klicke auf 'Login-Token' und kopiere das angezeigte Token (Strg + C ist am einfachsten).
- Wenn das CLI dich auffordert, gib dein Token ein. Per Rechtsklick in die Powershell-Konsole werden kopierte Inhalte eingefügt.
- Bestätige mit Eingabetaste.
"@

function Show-UserAndAddToGroup {
    param(
        [string]$ApiUrl
    )
    $ct = [ChurchTools]::new($ApiUrl)
    Out-Message "Authentifiziert als $($ct.User.firstName) $($ct.User.lastName)"
    $groupSignUpresult = $ct.AddUserToCLIGroup($VERSION)
    Out-Message $groupSignUpresult
}

function Set-CliEnv {
    Out-Line
    Out-Message  "Willkommen zum BGH-CLI!"
    Out-Line
    Out-Message  $initialSetupInfo
    Out-Line
    $envVars = @{}
    $envVars["CT_API_URL"] = Set-ApiUrl
    Save-ApiToken -ApiUrl $envVars["CT_API_URL"]
    $envVars["OUT_DIR"] = Set-OutDir
    Update-DotEnv -KeyValuePairs $envVars
    Show-UserAndAddToGroup -ApiUrl $envVars["CT_API_URL"]
    Out-Message "Danke für deine Angaben! Das CLI ist jetzt fertig konfiguriert."
}

Export-ModuleMember -Function Set-CliEnv, Save-ApiToken, Show-UserAndAddToGroup