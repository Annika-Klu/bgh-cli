Add-Type -AssemblyName System.Drawing

function Test-JsonContent {
    param (
        [string]$JsonPath
    )
    
    try {
        $content = Get-Content -Path $JsonPath -Raw
        $jsonObject = $content | ConvertFrom-Json
        return $true
    } catch {
        Out-Message "Ungültiges JSON in '$JsonPath'" -Type "error"
        Out-Message "Zur Validierung der Syntax nutze z. B. https://jsonlint.com" -Type "error"
        return $false
    }
}

function Get-JsonContent {
    param (
        [string]$JsonPath
    )
    
    $content = Get-Content -Path $JsonPath -Raw
    return  $content | ConvertFrom-Json
}

function Compress-FilesToZip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFolder,

        [Parameter(Mandatory = $true)]
        [string]$ZipFilePath 
    )

    if (Test-Path -Path $ZipFilePath) {
        Out-Message "Die ZIP-Datei '$ZipFilePath' existiert bereits. Sie wird überschrieben." -Type "warning"
        Remove-Item -Path $ZipFilePath
    }

    Out-Message "Komprimiere Dateien..."
    Compress-Archive -Path "$SourceFolder\*" -DestinationPath $ZipFilePath
}

function Get-DirStats {
    param (
        [string]$DirPath
    )

    if (Test-Path $DirPath) {
        $files = Get-ChildItem -Path $DirPath -File -Recurse
        $fileCount = $files.Count
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum

        $stats = [PSCustomObject]@{
            FileCount = $fileCount
            TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
        }

        return $stats
    } else {
        Write-Error "Der angegebene Pfad ist ungültig oder kein Verzeichnis."
    }
}

function Assert-FileNotOccupied {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    if (Test-Path $Path) {
        try {
            $stream = [System.IO.File]::Open($Path, 'Open', 'ReadWrite', 'None')
            $stream.Close()
        } catch {
            throw "Die Datei '$Path' wird gerade verwendet und kann nicht überschrieben werden."
        }
    }
}


# EXCEL

function Save-ExcelFile {
    param(
        [Parameter(Mandatory)]
        [Array]$Data,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$SheetName = "Sheet1",

        [switch]$Append
    )

    Assert-FileNotOccupied -Path $Path

    $exportParams = @{
        Path         = $Path
        WorkSheetname = $SheetName
        AutoSize     = $true
        BoldTopRow   = $true
        TableStyle   = "None"
        TableName    = $SheetName
    }

    if ($Append) {
        $exportParams.Append = $true
    } else {
        $exportParams.ClearSheet = $true
    }

    $Data | Export-Excel @exportParams
}

$ExcelColors = @{
    LightGray  = [System.Drawing.Color]::FromArgb(242, 242, 242) # Hellgrau
    Yellow  = [System.Drawing.Color]::FromArgb(255, 255, 0)   # Gelb
    Red    = [System.Drawing.Color]::FromArgb(255, 0, 0)     # Rot
}

function Set-HighlightColors {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$SheetName,

        [Parameter(Mandatory)]
        [int[]]$Rows,

        [int[]]$Cols = $null,

        [string]$ColorKey = "Yellow"
    )

    if (-not $ExcelColors.ContainsKey($ColorKey)) {
        throw "ColorKey '$ColorKey' ist nicht definiert. Verfügbar: $($ExcelColors.Keys -join ', ')"
    }

    $color = $ExcelColors[$ColorKey]

    $excelPackage = Open-ExcelPackage -Path $Path
    $worksheet = $excelPackage.Workbook.Worksheets[$SheetName]
    
    if (-not $Cols) {
        $colStart = $worksheet.Dimension.Start.Column
        $colEnd   = $worksheet.Dimension.End.Column
        $Cols = $colStart..$colEnd
    }

    foreach ($row in $Rows) {
        $colStart = $Cols[0]
        $colEnd = $Cols[-1]
        $range = $worksheet.Cells[$row, $colStart, $row, $colEnd]

        $range.Style.Fill.PatternType = "Solid"
        $range.Style.Fill.BackgroundColor.SetColor($Color)
    }

    Close-ExcelPackage $excelPackage
}