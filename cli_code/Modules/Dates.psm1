function Get-QuarterStartDate {
    param(
        [Int]$Quarter,
        [Int]$Year
    )

    $heute = Get-Date
    $definitionMode = "angegebenes"
    if (-not $Year) { $Year = $heute.Year }
    if (-not $Quarter) {
        $definitionMode = "kommendes" 
        $currentQuarter = [math]::Ceiling($heute.Month / 3)
        $Quarter = $currentQuarter + 1

        if ($Quarter -gt 4) {
            $Quarter = 1
            $Year += 1
        }
    }

    Out-Message "Erstelle Plan für $definitionMode Q$Quarter-$Year..."

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
