function Test-JsonContent {
    param (
        [string]$JsonPath
    )
    
    try {
        $content = Get-Content -Path $JsonPath -Raw
        $jsonObject = $content | ConvertFrom-Json
        return $true
    } catch {
        Out-Message "Ungültiges JSON in '$JsonPath': $_" -Type "error"
        Out-Message "Zur Validierung der Syntax nutze z. B. https://jsonlint.com" -Type "error"
        return $false
    }
}