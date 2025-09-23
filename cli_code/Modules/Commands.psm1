function Get-ParsedCmd {
    param (
        [string]$ArgsStr
    )
    
    $subcommands = @()
    $args = @{}
    $flags = @{}

    $tokens = $ArgsStr -split '\s+'
    
    foreach ($token in $tokens) {
        if ($token -match '^--.+$') {
            $tokenKey = $token -replace "^--", ""
            $flags[$tokenKey] = $true
        }
        elseif ($token -match '^[a-zA-Z0-9-]+=[a-zA-Z0-9-]+$') {
            $key, $value = $token -split '='
            $args[$key] = $value
        }
        else {
            $subcommands += $token
        }
    }

    return @{
        Subcommands = $subcommands
        Arguments   = $args
        Flags       = $flags
    }
}

function Get-CommandPath {
    param(
        [string]$CommandsDir,
        [string]$Command,
        [string[]]$SubCommands
    )
    $expectedPathParts = Join-Path $CommandsDir $Command
    if ($SubCommands.Count -gt 0) {
        $expectedPathParts = Join-Path $expectedPathParts ($SubCommands -join "\")
    }
    $expectedPath = $expectedPathParts + ".ps1"
    if (Test-Path $expectedPath) {
        return $expectedPath
    } 
    return ""
}