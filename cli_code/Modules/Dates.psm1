function Set-QuarterAndYear {
    $quarter = $parsedCmd.Arguments.quartal
    $year = $parsedCmd.Arguments.jahr
    $today = Get-Date

    if ($year) { 
        $year = Test-UserInput "Jahr" -Value $year -Type "int"
    } else { $year = $today.Year }

    if ($quarter) { 
        $quarter = Test-UserInput "Quartal" -Value $quarter -Type "int" -ValidValues @(1, 2, 3, 4)
    } else {
        $currentQuarter = [math]::Ceiling($today.Month / 3)
        $quarter = $currentQuarter + 1

        if ($quarter -gt 4) {
            $quarter = 1
            $year += 1
        }
    }
    
    return @($quarter, $year)
}

function Get-QuarterStartDate {
    param(
        [Int]$Quarter,
        [Int]$Year
    )

    switch ($Quarter) {
        1 {
            $startMonth = 1
            break
        }
        2 {
            $startMonth = 4
            break
        }
        3 {
            $startMonth = 7
            break
        }
        4 {
            $startMonth = 10
            break
        }
        default {
            Throw "Ungültiges Quartal: $Quarter"
        }
    }

    return Get-Date -Year $Year -Month $startMonth -Day 1
}
