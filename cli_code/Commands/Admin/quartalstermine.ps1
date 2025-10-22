function Assert-AppointmentsFile {
    param(
        [String]$FilePath
    )
 
    if (Test-Path $FilePath) { return }

    Out-Message "Termin-Konfigurationsdatei noch nicht vorhanden. Wird erstellt mit Beispielterminen..."
    $templatePath = Join-Path $PWD "data/$baseName.template.json"
    Copy-Item -Path $templatePath -Destination $FilePath
}

function Test-AppointmentsValid {
    param(
        [String]$FilePath
    )
    
    $contentValid = $true
    $appointments = Get-JsonContent -JsonPath $FilePath

    $mutuallyExclusiveProperties = @("tagmonat", "wochentag")
    foreach ($appointment in $appointments) {

        $matches = 0                
        foreach ($property in $mutuallyExclusiveProperties) {    
            if ($appointment.PSObject.Properties.Name -contains $property) { 
                $matches += 1
            }
        }
        $propertiesValid = ($matches -eq 1)

        if (-not $propertiesValid) { 
            $contentValid = $false
            $validProperties = $mutuallyExclusiveProperties -join ", "
            Out-Message "Eintrag '$($appointment.name)' muss genau eine der folgenden Eigenschaften haben: $($validProperties)" -Type "error"
        }

        $tagmonatPattern = "^(?<_day>\d{2})\.(?<_month>\d{2})\.$"
        if ($appointment.PSObject.Properties.Name -contains "tagmonat") {
            if ($appointment.tagmonat -notmatch $tagmonatPattern) {
                $contentValid = $false
                Out-Message "Eintrag '$($appointment.name)' hat falschen Wert für 'tagmonat'. Format: 'dd.MM.'" -Type "error"
            } else {
                $day = [int]$matches["_day"]
                if ($day -lt 1 -or $day -gt 31) {
                    $contentValid = $false
                    Out-Message "Eintrag '$($appointment.name)' hat falschen Tageswert für 'tagmonat'. Erlaubt: 1-31" -Type "error"
                }

                $month = [int]$matches['_month']
                if ($month -lt 1 -or $month -gt 12) {
                    $contentValid = $false
                    Out-Message "Eintrag '$($appointment.name)' hat falschen Monatswert für 'tagmonat'. Erlaubt: 1-12" -Type "error"
                }
            }
        }
    }
    return $contentValid
}

function Edit-AppointmentsFile {
    param(
        [String]$FilePath
    )

    do {
        $editor = "notepad.exe"
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

        $proc = Start-Process -FilePath $editor -ArgumentList $FilePath -PassThru

        Out-Message "Speichere und schließe '$baseName.json', wenn du mit der Bearbeitung fertig bist."
        $proc.WaitForExit()

        $syntaxValid = Test-JsonContent -JsonPath $FilePath
        
        $contentValid = $true
        if ($syntaxValid) {
           $contentValid = Test-AppointmentsValid -FilePath $FilePath
        }
        $isValid = ($syntaxValid -and $contentValid)
    } while (-not $isValid)
}

$daysMap = @{
    "Mo" = [DayOfWeek]::Monday
    "Di" = [DayOfWeek]::Tuesday
    "Mi" = [DayOfWeek]::Wednesday
    "Do" = [DayOfWeek]::Thursday
    "Fr" = [DayOfWeek]::Friday
    "Sa" = [DayOfWeek]::Saturday
    "So" = [DayOfWeek]::Sunday
}

function Get-AppointmentDates {
    param(
        [String]$FilePath,
        [Datetime]$StartDate
    )
    
    $appointmentSchedule = Get-JsonContent -JsonPath $FilePath
    $allAppointments = @()

    foreach ($appointment in $appointmentSchedule) {
        $name = $appointment.name
        
        $weeksOfMonth = if ($appointment.PSObject.Properties.Name -contains "monatswoche") { $appointment.monatswoche } else { $null }
        $dayMonth = if ($appointment.PSObject.Properties.Name -contains "tagmonat") { $appointment.tagmonat } else { $null }
        $weekday = if ($appointment.PSObject.Properties.Name -contains "wochentag") { $daysMap[$appointment.wochentag] } else { $null }

        $time = $appointment.uhrzeit
        $parts = $time -split "\."
        $hours = [int]$parts[0]
        $minutes = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }

        for ($month = 0; $month -lt 3; $month++) {
            $monthStart = (Get-Date -Year $StartDate.Year -Month $StartDate.Month -Day 1).AddMonths($month)
            $monthEnd = $monthStart.AddMonths(1).AddDays(-1)

            $daysOfMonth = @()
            for ($d = $monthStart; $d -le $monthEnd; $d = $d.AddDays(1)) {
                if ($weekday -and $d.DayOfWeek -eq $weekday) {
                    $daysOfMonth += $d
                }
            }

            $selectedDays = @()
            if ($weeksOfMonth) {
                foreach ($week in $weeksOfMonth) {
                    $index = [int]$week - 1
                    if ($index -lt $daysOfMonth.Count) {
                        $selectedDays += $daysOfMonth[$index]
                    }
                }
            } elseif ($dayMonth) {
                $parts = $dayMonth -split "\."
                $dayMonthDate = Get-Date -Day $parts[0] -Month $parts[1] -Year $StartDate.year
                if ($dayMonthDate -ge $monthStart -and $dayMonthDate -le $monthEnd) {
                    $selectedDays += $dayMonthDate
                }

            } else {
                $selectedDays = $daysOfMonth
            }

            foreach ($day in $selectedDays) {
                $parts = $time -split "\."
                $hours = [int]$parts[0]
                $minutes = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }

                $datetime = Get-Date -Year $day.Year -Month $day.Month -Day $day.Day -Hour $hours -Minute $minutes
                $allAppointments += [PSCustomObject]@{
                    Name     = $name
                    DatumObjekt = $datetime
                    Datum    = $datetime.ToString("dd.MM.yyyy")
                    Uhrzeit  = $datetime.ToString("HH:mm")
                    Wochentag = $datetime.ToString("ddd", [System.Globalization.CultureInfo]::GetCultureInfo("de-DE")) #$datetime.DayOfWeek
                }
            }
        }
    }
    return $allAppointments
}

$baseName = "quartalstermine"
$quarter = $parsedCmd.Arguments.quartal
$year = $parsedCmd.Arguments.jahr

try {
    $filePath = Join-Path $OUT_DIR "$baseName.json"
    $editedDueToSyntaxErr = Assert-AppointmentsFile -FilePath $filePath

    if (-not $editedDueToSyntaxErr) {
        $editFile = Get-YesOrNo "Möchtest du die Termin-Konfigurationsdatei bearbeiten?"
        if ($editFile) { Edit-AppointmentsFile -FilePath $filePath }
    }
    
    if ($quarter) { $quarter = Test-UserInput "Quartal" -Value $quarter -Type "int" -ValidValues @(1, 2, 3, 4) }
    if ($year) { $year = Test-UserInput "Jahr" -Value $year -Type "int" }
    $startDate = Get-QuarterStartDate -Quarter $quarter -Year $year
    
    $appointments = Get-AppointmentDates -FilePath $filePath -StartDate $startDate
    $appointments | Sort-Object DatumObjekt | Select-Object Name, Datum, Uhrzeit, Wochentag  | Format-Table -AutoSize
} catch {
    Out-Message $_.Exception.Message -Type "error"
    Write-ErrorMessage -Log $log -ErrMsg $_.Exception.Message
    Send-ErrorReport -ErrMsg $_.Exception.Message
}