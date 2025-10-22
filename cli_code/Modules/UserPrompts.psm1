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
        $response = Read-Host "$Message (j/n)"
        $responseIsValid = $validResponses.ContainsKey($response)
        if (-not $responseIsValid) {
            Out-Message "Ungültige Eingabe, bitte 'j' oder 'n' angeben." -Type "error"
        }
    } until ($responseIsValid)

    return $validResponses[$response]
}
