class Timer {
    [datetime]$startTime
    [datetime]$endTime

    # Timer() {
    #     $this.startTime = $null
    #     $this.endTime = $null
    # }

    [void] Start() {
        $this.startTime = Get-Date
    }

    [void] Stop() {
        $this.endTime = Get-Date
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

    [void] LogTimeAs([string]$message) {
        $currentTime = Get-Date
        Out-Message "$($message): $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    }
}