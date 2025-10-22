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

function Initialize-ExcelObjects {
    param(
        [Switch]$Visible
    )
    try {
        $excel = New-Object -ComObject Excel.Application
    } catch {
        throw "Excel konnte nicht gestartet werden. Möglicherweise ist es nicht installiert. Fehlermeldung: $_"
    }
    $excel.Visible = $Visible
    $workbook = $excel.Workbooks.Add()
    return @($excel, $workbook)
}

function Add-ExcelTableData {
    param(
        [Object]$Sheet,
        [Array]$Headers,
        [Array]$Data
    )

    $row = 1
    for ($col = 0; $col -lt $Headers.Count; $col++) {
        $Sheet.Cells.Item($row, $col + 1).Value2 = $Headers[$col]
        $Sheet.Cells.Item($row, $col + 1).Font.Bold = $true
    }

    $row = 2
    foreach ($item in $Data) {
        $col = 1
        foreach ($key in $item.PSObject.Properties.Name) {
            if (-not $Headers.contains($key)) { continue }
            $Sheet.Cells.Item($row, $col).Value2 = $item.$key
            $col++
        }
        $row++
    }
}

function Unregister-Excel {
    param(
        [Object]$Excel,
        [Object]$Workbook,
        [Object]$Sheet
    )
    $Workbook.Close($false) | Out-Null
    $Excel.Quit() | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
    [GC]::Collect() | Out-Null
    [GC]::WaitForPendingFinalizers() | Out-Null
}