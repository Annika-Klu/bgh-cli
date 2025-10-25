class Holidays {
    [string[]]$FederalStates
    [object[]]$PublicHolidays = @()
    [object[]]$SchoolHolidays = @()
    [int]$Year
    [string]$APIBaseUrl

    Holidays([string[]]$bundeslaender) {
        $this.FederalStates = $bundeslaender
        $this.Year = (Get-Date).Year
        $this.APIBaseUrl = "https://openholidaysapi.org"
        $fromAndToParams = "&validFrom=$($this.Year)-01-01&validTo=$($this.Year)-12-31"

        $urlPublicHolidays = "$($this.APIBaseUrl)/PublicHolidays?countryIsoCode=DE$fromAndToParams"
        try {
            $this.PublicHolidays = Invoke-RestMethod -Uri $urlPublicHolidays
        } catch {
            Write-Warning "Feiertage konnten nicht geladen werden. $_"
            $this.PublicHolidays = @()
        }

        $urlShoolHolidays = "$($this.APIBaseUrl)/SchoolHolidays?countryIsoCode=DE$fromAndToParams"
        try {
            $this.SchoolHolidays = Invoke-RestMethod -Uri $urlShoolHolidays
        } catch {
            Write-Warning "Ferien konnten nicht geladen werden. $_"
            $this.SchoolHolidays = @()
        }
    }

    [object] IsPublicHoliday([datetime]$date) {
        $dateDayOnly = $date.Date

        foreach ($publicHoliday in $this.PublicHolidays) {
            $publicHolidayDate = [datetime]$publicHoliday.startDate
            $relevant = $publicHoliday.nationwide
            $location = "Gesetzlicher Feiertag"
            $relevantFederalStates = @()

            if (-not $publicHoliday.nationwide) {
                foreach ($subdivision in $publicHoliday.subdivisions) {
                    $federalState = $subdivision.shortName
                    if ($this.FederalStates -contains $federalState) {
                        $relevant = $true
                        $relevantFederalStates += $federalState
                    }
                }
                $location = ($relevantFederalStates | Sort-Object -Unique) -join ", "
            }

            if ($relevant -and $publicHolidayDate.Date -eq $dateDayOnly) {
                $deNameObjekt = $publicHoliday.name | Where-Object { $_.language -eq "DE" }
                $name = if ($deNameObjekt) { $deNameObjekt.text } else { "Unbenannter Feiertag" }
                return @{
                    name = $name
                    location = $location
                }
            }
        }

        return $null
    }

    [object] IsSchoolHoliday([datetime]$date) {
        $dateDayOnly = $date.Date
        $relevantFederalStates = @()
        $name = ""

        foreach ($shoolHolidaysBlock in $this.SchoolHolidays) {
            $start = [datetime]$shoolHolidaysBlock.startDate
            $ende = [datetime]$shoolHolidaysBlock.endDate

            if ($dateDayOnly -ge $start.Date -and $dateDayOnly -le $ende.Date) {
                foreach ($subdiv in $shoolHolidaysBlock.subdivisions) {
                    $federalState = $subdiv.shortName
                    if ($this.FederalStates -contains $federalState) {
                        $relevantFederalStates += $federalState
                    }
                }

                if ($shoolHolidaysBlock.name) {
                    $deNameObjekt = $shoolHolidaysBlock.name | Where-Object { $_.language -eq "DE" }
                    if ($deNameObjekt -and $deNameObjekt.text -and $name -notlike "*$($deNameObjekt.text)*") {
                        if ($name -ne "") { $name += ", " }
                        $name += $deNameObjekt.text
                    }
                }
            }
        }

        if ($relevantFederalStates.Count -gt 0) {
            return @{
                name     = $name
                location = ($relevantFederalStates | Sort-Object -Unique) -join ", "
            }
        }

        return $null
    }

    [object] IsDayOff([datetime]$date) {
        $publicHoliday = $this.IsPublicHoliday($date)
        if ($publicHoliday) {
            return $publicHoliday
        }
        return $this.IsSchoolHoliday($date)
    }
}