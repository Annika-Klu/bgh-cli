function Get-AllowedCommands {
    $allowedCommands = @()
    $ct = [ChurchTools]::new($CT_API_URL)

    Get-ChildItem -Path "$PWD\Commands" -Filter *.ps1 -Recurse | ForEach-Object {
        $commandFile = $_.FullName
        $accessFile = Join-Path $_.Directory.FullName ".access"

        $isAllowed = $false

        if (Test-Path $accessFile) {
            $content = Get-Content $accessFile -Raw
            if ($content -match '^groups\s*=\s*(.+)$') {
                $groupsString = $matches[1].Trim()
                if ($groupsString -eq "*") {
                    $isAllowed = $true
                } else {
                    $allowedGroups = $groupsString -split '\s*,\s*'
                    $isAllowed = $ct.UserHasAccess($allowedGroups)
                }
            }
        }

        if ($isAllowed) {
            $allowedCommands += $_
        }
    }

    return $allowedCommands
}

Export-ModuleMember -Function Get-AllowedCommands