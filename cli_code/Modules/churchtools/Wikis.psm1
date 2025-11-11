function Get-Wikis {
    $ct = [ChurchTools]::new($CT_API_URL)
    return $ct.PaginateRequest("wiki/categories", 100)
}

function Get-WikiPages {
    param(
        [int]$WikiCategoryId
    )
    $ct = [ChurchTools]::new($CT_API_URL)
    return $ct.PaginateRequest("wiki/categories/$WikiCategoryId/pages", 100)
}

function Save-WikiPage {
    param(
        [int]$WikiCategoryId,
        [guid]$WikiPageId,
        [string]$SavePath
    )
    $ct = [ChurchTools]::new($CT_API_URL)
    $content = $ct.CallApi("GET", "wiki/categories/$WikiCategoryId/pages/$WikiPageId", $null, $null)
    Set-Content -Path $SavePath -Value $content.data.text
}

function Save-WikiPageFiles {
    param(
        [int]$WikiCategoryId,
        [guid]$WikiPageId,
        [string]$SaveDir
    )

    $ct = [ChurchTools]::new($CT_API_URL)
    $files = $ct.CallApi("GET", "files/wiki_$WikiCategoryId/$WikiPageId", $null, $null)
    if ($files.Count -eq 0) {
        return
    }
    foreach ($file in $files.data) {
        $savePath = Join-Path $SaveDir $file.name
        $ct.CallApi("GET", $file.fileUrl, $null, $savePath) | Out-Null
    }
}