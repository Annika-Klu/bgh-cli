param (
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalArgs
)

Set-Location -Path $PSScriptRoot

. "$PSScriptRoot/preflight/run.ps1"

function Use-MentionHelp {
    Out-Message "Mit 'bgh hilfe' kannst du eine Liste aller Befehle anzeigen lassen."
}

try {
    if (-not $Command) {
        Out-Message "Bitte Befehl eingeben und mit der Eingabetaste bestätigen."
        Use-MentionHelp
        exit 1
    }

    $args = @{}
    if ($AdditionalArgs.Count -gt 0) {
        $argsStr = $AdditionalArgs -join " "
        $args = Get-ParsedArgs -ArgsStr $argsStr
    }

    if ($args.Flags.debug) {
        Out-Message "Subcommands: $($args.Subcommands -join ', ')" debug
        Out-Message "Arguments: $($args.Arguments | Out-String)" debug
        Out-Message "Flags: $($args.Flags | Out-String)" debug
    }
    
    $commandsDir = Join-Path $PSScriptRoot "Commands"
    $commandPath = Get-CommandPath -CommandsDir $commandsDir -Command $Command -SubCommands $args.Subcommands
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
