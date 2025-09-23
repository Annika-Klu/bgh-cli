function Save-EncryptedToken {
    param (
        [Parameter(Mandatory)]
        [string]$Token,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $Token |
        ConvertTo-SecureString -AsPlainText -Force |
        ConvertFrom-SecureString |
        Set-Content -Path $Path -Encoding UTF8
}

function Get-EncryptedToken {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$AsPlainText
    )

    $secureToken = Get-Content -Path $Path -Encoding UTF8 | ConvertTo-SecureString

    if ($AsPlainText) {
        return [System.Net.NetworkCredential]::new("", $secureToken).Password
    } else {
        return $secureToken
    }
}


Export-ModuleMember -Function Save-EncryptedToken, Get-EncryptedToken