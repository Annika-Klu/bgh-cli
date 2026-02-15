function Install-Cli {
    param(
        [string]$InstallPath
    )

    if (Test-Path $TestRoot) {
        Remove-Item $TestRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $TestRoot | Out-Null
    Copy-Item "$source\*" $TestRoot -Recurse -Force
    Get-ChildItem $TestRoot -Recurse -Include *.json,*.sec | Remove-Item -Force

    Write-Host "CLI installed" -ForegroundColor Cyan
}