$GitHubHeaders = @{ Authorization = "Bearer $GH_TOKEN" }

function Get-LatestRelease {
    param(
        [string]$ReleasesUrl
    )
    try {
        $response = Invoke-WebRequest -Uri $ReleasesUrl -Headers $GitHubHeaders
    } catch {
        throw "Letzter Release konnte nicht abgefragt werden: $_"
    }
    $releases = $response.Content | ConvertFrom-Json
    if ($releases.Count -eq 0) {
        throw "Kein Release gefunden."
    }
    $latestRelease = $releases | Sort-Object { [datetime]$_.published_at } -Descending | Select-Object -First 1
    return $latestRelease
}

function Get-ReleaseAsset {
    param(
        [PSObject]$Release,
        [string]$AssetName
    )
    $assetsResponse = Invoke-WebRequest -Uri $Release.assets_url -Headers $GitHubHeaders
    $assets = $assetsResponse.Content | ConvertFrom-Json
    if ($assets.Count -eq 0) {
        throw "Keine Assets für Release $($Release.tag_name) gefunden."
    }
    $asset = $assets | Where-Object { $_.name -eq $AssetName }
    if (-not $asset) {
        throw "Die relevanten Dateien wurden nicht in den Release Assets gefunden."
    }
    return $asset
}

Export-ModuleMember -Function Get-LatestRelease, Get-ReleaseAsset