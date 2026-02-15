function Install-Cli {
    param(
        [string]$InstallPath
    )

    if (Test-Path $InstallPath) {
        Remove-Item $InstallPath -Recurse -Force
    }
    
    $source = "$PSScriptRoot\..\cli_code"
    New-Item -ItemType Directory -Path $InstallPath | Out-Null
    Copy-Item "$source\*" $InstallPath -Recurse -Force
    Get-ChildItem $InstallPath -Recurse -Include *.json,*.sec | Remove-Item -Force

    Write-Host "CLI installed" -ForegroundColor Cyan
}