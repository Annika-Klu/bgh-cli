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