function Assert-AppointmentsFile {
    param(
        [String]$FilePath
    )
 
    if (Test-Path $FilePath) { return }

    Out-Message "Termin-Konfigurationsdatei noch nicht vorhanden. Wird erstellt mit Beispielterminen..."
    $templatePath = Join-Path $PWD "data/$baseName.template.json"
    Copy-Item -Path $templatePath -Destination $FilePath
}

function Edit-AppointmentsFile {
    param(
        [String]$FilePath
    )

    # $editor = "notepad.exe"
    # $proc = Start-Process -FilePath $editor -ArgumentList $FilePath -PassThru

    # Out-Message "Bitte schließe die Datei '$baseName.json', wenn du mit der Bearbeitung fertig bist."
    # $proc.WaitForExit()
    do {
        $editor = "notepad.exe"
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

        $proc = Start-Process -FilePath $editor -ArgumentList $FilePath -PassThru

        Out-Message "Speichere und schließe '$baseName.json', wenn du mit der Bearbeitung fertig bist."
        $proc.WaitForExit()

        $isValid = Test-JsonContent -JsonPath $FilePath
        
        if ($isValid) {
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
                    $isValid = $false
                    $validProperties = $mutuallyExclusiveProperties -join ", "
                    Out-Message "Eintrag '$($appointment.name)' muss genau eine der folgenden Eigenschaften haben: $($validProperties)" -Type "error"
                }
            }
        }
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
        $weeksOfMonth = if ($appointment.PSObject.Properties.Match("monatswoche")) { $appointment.monatswoche } else { $null }
        $weekday = $daysMap[$appointment.wochentag]

        $time = $appointment.uhrzeit
        $parts = $time -split "\."
        $hours = [int]$parts[0]
        $minutes = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }

        for ($month = 0; $month -lt 3; $month++) {
            $monthStart = (Get-Date -Year $StartDate.Year -Month $StartDate.Month -Day 1).AddMonths($month)
            $monthEnd = $monthStart.AddMonths(1).AddDays(-1)

            $daysOfMonth = @()
            for ($d = $monthStart; $d -le $monthEnd; $d = $d.AddDays(1)) {
                if ($d.DayOfWeek -eq $weekday) {
                    $daysOfMonth += $d
                }
            }

            if ($weeksOfMonth) {
                $selectedDays = @()
                foreach ($week in $weeksOfMonth) {
                    $index = [int]$week - 1
                    if ($index -lt $daysOfMonth.Count) {
                        $selectedDays += $daysOfMonth[$index]
                    }
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