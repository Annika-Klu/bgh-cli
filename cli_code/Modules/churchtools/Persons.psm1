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