function Show-Help {
    Out-Message "`nLISTE DER BEFEHLE"

    $allowedCommands = Get-AllowedCommands
    $groups = $allowedCommands | Group-Object DirectoryName | Sort-Object Name

    foreach ($group in $groups) {
        Write-Host ""
        
        $relativePath = $group.Name -replace [regex]::Escape($PSScriptRoot), ''
        $relativePath = $relativePath.TrimStart('\','/')
        $folderName = Split-Path $relativePath -Leaf

        if ($folderName -match "Commands") {
            Out-Message ("{0,-14} {1}" -f "[Allgemein]", "Verwendung: 'bgh <befehl>'`n")
        } else {
            Out-Message ("{0,-14} {1}" -f "[$folderName]" , "Verwendung: 'bgh $folderName <befehl>'`n")
        }

        $helpItems = foreach ($cmd in $group.Group | Sort-Object Name) {
            $name = $cmd.BaseName
            $descFile = $cmd.FullName -replace "\.ps1$", ".md"

            if (Test-Path $descFile) {
                $descLines = Get-Content $descFile
                if (-not ($descLines -is [System.Array])) {
                    $descLines = @($descLines)
                }
            } else {
                $descLines = @("(Keine Beschreibung)")
            }

            [PSCustomObject]@{
                Name        = $name
                FirstLine   = $descLines[0]
                ExtraLines  = $descLines | Select-Object -Skip 1
            }
        }

        foreach ($item in $helpItems) {
            Out-Message ("- {0,-12} {1}" -f $item.Name, $item.FirstLine) 

            foreach ($line in $item.ExtraLines) {
                Out-Message ("  {0,-12} {1}" -f "", $line)
            }
        }
    }
    Write-Host ""
}