function Get-Birthdays {
    param(
        [Datetime]$From,
        [Datetime]$To
    )

    $ct = [ChurchTools]::new($CT_API_URL)
    $url = "persons/birthdays?start_date=$(Get-ApiDate $From)&end_date=$(Get-ApiDate $To)"
    $birthdaysRes = $ct.CallApi("GET", $url, $null, $null)
    
    $birthdays = @()
    foreach($entry in $birthdaysRes.data) {
        $birthdayDate = [datetime]$entry.anniversary
        $personAttrs = $entry.person.domainAttributes
        $personShortName = "$($personAttrs.firstName) $($personAttrs.lastName[0])."
        $birthday = [PSCustomObject]@{
            Name = $personShortName
            Tag = $birthdayDate.ToString("dd.MM.")
        }
        $birthdays += $birthday
    }
    return $birthdays
}

function Get-PersonsBackupData {
    param(
        [Array]$StatusNames
    )

    $ct = [ChurchTools]::new($CT_API_URL)
    Out-Message "Berücksichtige folgende Status: $($StatusNames -join ', ')"

    $statuses = $ct.PaginateRequest("statuses", 10)
    $statusIds = $statuses | Where-Object { $StatusNames -contains $_.nameTranslated } | Select-Object -Expand id
    
    $statusMap = @{}
    $statuses | ForEach-Object { $statusMap[$_.id] = $_.nameTranslated }

    $persons = $ct.PaginateRequest("persons", 100)

    $allPersonsData = @()
    foreach ($person in $persons) {
        if (-not ($statusIds -contains $person.statusId)) {
            if ($parsedCmd.Flags.debug) {
                Out-Message "Ignoriere $($person.firstName) $($person.lastName) (keine der relevanten Status-Id)" -Type "debug"
            }
            continue
        }
       
        try {
            $dateObj =[datetime]$person.birthday
            $birthday = $dateObj.toString("dd.MM.yyyy")
        } catch {
            $birthday = $person.birthday
        }
        $allPersonsData += [PSCustomObject]@{
            Vorname = $person.firstName
            Nachame   = $person.lastName
            Status = $statusMap[$person.statusId]
            Email = $person.email
            Spitzname = $person.nickname
            Geburtstag  = $birthday
            Tel = $person.phonePrivate
            Mobil = $person.mobile
            Strasse = $person.street
            PLZ = $person.zip
            Ort = $person.city
            Land = $person.country
        }
    }
    return $allPersonsData
}