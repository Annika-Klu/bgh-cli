$EnvPath = Join-Path $PWD ".env"

function Get-DotEnv {
    if (-Not (Test-Path $EnvPath)) {
        Throw "File not found: $EnvPath"
    }

    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^\s*([^#][\w\.]+)\s*=\s*(.*)$') {
            $name, $value = $matches[1], $matches[2]
            Set-Variable -Name $name -Value $value -Scope Global
        }
    }
}

function Update-DotEnv {
    param(
        [hashtable]$KeyValuePairs
    )

    $envContent = @(Get-Content -Path $EnvPath -ErrorAction SilentlyContinue)

    foreach ($key in $KeyValuePairs.Keys) {
        $value = $KeyValuePairs[$key]

        $found = $false

        for ($i = 0; $i -lt $envContent.Count; $i++) {
            if ($envContent[$i] -match "^\s*$key\s*=") {
                $envContent[$i] = "$key=$value"
                $found = $true
                break
            }
        }

        if (-not $found) {
            $envContent += "$key=$value"
        }
    }

    $envContent | Out-File -FilePath $EnvPath -Encoding utf8 -NoNewline:$false
}

Export-ModuleMember -Function Get-Dotenv, Update-DotEnv