function Test-JsonContent {
    param (
        [string]$JsonPath
    )
    
    try {
        $content = Get-Content -Path $JsonPath -Raw
        $jsonObject = $content | ConvertFrom-Json
        return $true
    } catch {
        Out-Message "Ungültiges JSON in '$JsonPath'" -Type "error"
        Out-Message "Zur Validierung der Syntax nutze z. B. https://jsonlint.com" -Type "error"
        return $false
    }
}

function Get-JsonContent {
    param (
        [string]$JsonPath
    )
    
    $content = Get-Content -Path $JsonPath -Raw
    return  $content | ConvertFrom-Json
}