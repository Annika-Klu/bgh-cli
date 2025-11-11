class Timer {
    [datetime]$startTime
    [datetime]$endTime
    [datetime]$Marker

    [void] Start() {
        $this.startTime = Get-Date
    }

    [void] Stop() {
        $this.endTime = Get-Date
    }

    [void] SetMarker() {
        $this.Marker = Get-Date
    }

    [void] LogDuration([string]$message) {
        if ($this.startTime -eq $null) {
            Out-Message "Der Timer wurde noch nicht gestartet." -Type "error"
            return
        }

        $currentTime = if ($this.endTime) { $this.endTime } else { Get-Date }
        $elapsedTime = $currentTime - $this.startTime
        $formattedDuration = [string]::Format("{0:D2}:{1:D2}:{2:D2}", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds)
        Out-Message "$message $formattedDuration"
    }

    [void] LogDurationSinceMarker([string]$message) {
        if ($this.Marker -eq $null) {
            Out-Message "Es wurde noch kein Marker gesetzt." -Type "error"
            return
        }
        $currentTime = Get-Date
        $elapsedTime = $currentTime - $this.Marker
        $formattedDuration = [string]::Format("{0:D2}:{1:D2}:{2:D2}", $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds)
        Out-Message "$message $formattedDuration"
    }
}