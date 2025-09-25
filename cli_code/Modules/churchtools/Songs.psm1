
function Get-AllSongFiles {
    $ct = [ChurchTools]::new($CT_API_URL)
    $songs = $ct.PaginateRequest("songs", 100)
    $songFiles = @()
    
    foreach ($song in $songs) {
        foreach ($arragement in $song.arrangements) {
            $pptFiles = $arragement.files | Where-Object { $_.name.Contains(".pptx")}
            if ($pptFiles) {
                $songFiles = $songFiles + $pptFiles
            }
        }
    }
    return $songFiles
}

function Revoke-SongFilesNotFound {
    param(
        [array]$ApiSongFiles,
        [string]$SongsDir
    )

    $existingFiles = Get-ChildItem -Path $SongsDir -File
    $filesToDelete = $existingFiles | Where-Object {
        $file = $_
        -not ($ApiSongFiles | Where-Object { $file.name -eq $_.Name })
    }
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName -Force
    }
    return $filesToDelete.Count
}

function Sync-FromLocalToChurchtools {
    param(
        [array]$SongFiles,
        [string]$SongsDir
    )
    
    if (-not (Test-Path $SongsDir)) {
        New-Item -ItemType Directory -Path $SongsDir | Out-Null
    }

    $ct = [ChurchTools]::new($CT_API_URL)
    $stats = @{
        "total" = $songFiles.Count
        "new" = 0
        "updated" = 0
    }

    $stats["deleted"] = Revoke-SongFilesNotFound -ApiSongFiles $SongFiles -SongsDir $SongsDir
    
    foreach ($file in $SongFiles) {
        $savePath = Join-Path $SongsDir $file.name
        if (Test-path $savePath) {
            $lastModifiedDateStr = $file.meta.modifiedDate
            $apiFileLastModified = [DateTime]::ParseExact($lastModifiedDateStr, "yyyy-MM-ddTHH:mm:ssZ", $null)
            $savedFileLastModified = (Get-Item $savePath).LastWriteTime
            if ($apiFileLastModified -gt $savedFileLastModified) {
                $stats["updated"]++
                $ct.CallApi("GET", $file.fileUrl, $null, $savePath)
            }
            continue
        }
        $stats["new"]++
        $ct.CallApi("GET", $file.fileUrl, $null, $savePath)
    }
    return $stats
}