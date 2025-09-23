class Log {
    [string]$Name
    [string]$LogsPath
    [string]$FullPath

    Log([string]$Name) {
        $this.Name = $Name
        $this.LogsPath = "$PSScriptRoot\..\logs"
        if (-not (Test-Path $this.LogsPath)) {
            New-Item -ItemType Directory -Path $this.LogsPath | Out-Null
        }
        $this.FullPath = Join-Path $this.LogsPath ("$Name.log")
    }

    [void] Write([string]$Message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "[$timestamp] $Message"

        Add-Content -Path $this.FullPath -Value $entry
    }
}

$log = [Log]::new("bgh")