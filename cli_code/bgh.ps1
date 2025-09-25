param (
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalArgs
)

Set-Location -Path $PSScriptRoot

. "$PSScriptRoot/preflight/run.ps1" -Command $Command

function Use-MentionHelp {
    Out-Message "Mit 'bgh hilfe' kannst du eine Liste aller Befehle anzeigen lassen."
}

try {
    if (-not $Command) {
        Out-Message "Bitte Befehl eingeben und mit der Eingabetaste bestätigen."
        Use-MentionHelp
        exit 1
    }

    $parsedCmd = @{}
    if ($AdditionalArgs.Count -gt 0) {
        $parsedCmdStr = $AdditionalArgs -join " "
        $parsedCmd = Get-ParsedCmd -ArgsStr $parsedCmdStr
        Set-Variable -Name "parsedCmd" -Value $parsedCmd -Scope Global
    }

    if ($parsedCmd.Flags.debug) {
        Out-Message "Subcommands: $($parsedCmd.Subcommands -join ', ')" debug
        Out-Message "Arguments: $($parsedCmd.Arguments | Out-String)" debug
        Out-Message "Flags: $($parsedCmd.Flags | Out-String)" debug
    }
    
    $commandsDir = Join-Path $PSScriptRoot "Commands"
    $commandPath = Get-CommandPath -CommandsDir $commandsDir -Command $Command -SubCommands $parsedCmd.Subcommands
    if (-not $commandPath) {
        Out-Message "'$Command $AdditionalArgs' ist kein gültiger Befehl."
        Use-MentionHelp
        exit 1
    }

    $allowedCommands = Get-AllowedCommands
    $ct = [ChurchTools]::new($CT_API_URL)

    if ($allowedCommands.FullName -notcontains $commandPath) {
        Out-Message "Du bist nicht berechtigt, diesen Befehl auszuführen." -Type error
        throw "User $($ct.User.email) is not allowed to run command '$Command'."
    }
    . $commandPath @($AdditionalArgs)

    exit 0
} catch {
    Out-Message $_ error
    $log.Write("Error in bgh.ps1 $($_.Exception.Message)")
}
