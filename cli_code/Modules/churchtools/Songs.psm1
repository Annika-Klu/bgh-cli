
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

    $existingFiles = Get-ChildItem -Path $songsDir -File
    $filesToDelete = $existingFiles | Where-Object {
        $file = $_
        -not ($ApiSongFiles | Where-Object { $file.name -eq $_.Name })
    }
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName -Force
    }
    return $filesToDelete.Count
}

function Sync-SongFiles {
    param(
        [array]$SongFiles
    )
    $songsDir = Join-Path $OUT_DIR "Lieder"
    if (-not (Test-Path $songsDir)) {
        New-Item -ItemType Directory -Path $songsDir | Out-Null
    }

    $ct = [ChurchTools]::new($CT_API_URL)
    $stats = @{
        "total" = $songFiles.Count
        "new" = 0
        "updated" = 0
    }

    $stats["deleted"] = Revoke-SongFilesNotFound -ApiSongFiles $SongFiles -SongsDir $songsDir
    
    foreach ($file in $SongFiles) {
        $savePath = Join-Path $songsDir $file.name
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