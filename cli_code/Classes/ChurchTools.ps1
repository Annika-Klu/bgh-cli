class ChurchTools {
    [string]$BaseUrl
    [object]$Headers
    [pscustomobject]$User
    [string]$CachePath

    ChurchTools([string]$apiUrl) {
        $this.BaseUrl = $apiUrl
        $tokenPath = Join-Path $PWD "ctlogintoken.sec"
        $token = Get-EncryptedToken -Path $tokenPath -AsPlainText
        $this.Headers = @{ Authorization = "Login $($token)" }
        $this.CachePath = "$PSScriptRoot\..\.usercache.json"
        $this.LoadUserData()
    }

    [object] CallApi([string]$Method, [string]$Path, [object]$Body, [string]$OutFile) {
        if ($Path -match '^https?://') {
            $uri = $Path
        } else {
            $uri = "$($this.BaseUrl)/$Path"
        }

        $params = @{
            Method      = $Method
            Uri         = $uri
            Headers     = $this.Headers
            ErrorAction = 'Stop'
        }

        if ($Body -ne $null) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $params['Body'] = $jsonBody
            $params['ContentType'] = 'application/json'
        }

        if ($OutFile) {
            $params['OutFile'] = $OutFile
            Invoke-WebRequest @params
            return $OutFile
        } else {
            $response = Invoke-WebRequest @params
            return $response.Content | ConvertFrom-Json
        }
    }

    [object] PaginateRequest([string]$Path, [int]$Limit) {
        $allData = @()
        $pagination = @{
            "current" = 1
            "lastPage"  = 9999
            "limit" = $Limit
        }
        
        do {
            $url = "$($Path)?direction=forward&page=$($pagination['current'])&limit=$Limit"
            $response = $this.CallApi("GET", $url, $null, $null)
            $allData += $response.data
            if ($pagination['lastPage'] -ne $response.meta.pagination.lastPage) {
                $pagination['lastPage'] = $response.meta.pagination.lastPage
            }
            $pagination['current']++
        } while ($pagination['current'] -le $pagination['lastPage'])
        return $allData
    }

    [void] LoadUserData() {
        if (Test-Path -Path $this.CachePath) {
            $this.User = Get-Content $this.CachePath -Raw | ConvertFrom-Json
        } else {
            try {
                Out-Message "Lade Nutzerdaten..."
                $userRes = $this.CallApi("GET", "whoami", $null, $null)
                # to do: identify CLI group and if user is not a member, add them. Separate method.
                $groups = $this.CallApi("GET", "persons/$($userRes.data.id)/groups", $null, $null)
                $this.User = [PSCustomObject]@{
                    firstName   = $userRes.data.firstName
                    lastName = $userRes.data.lastName
                    email  = $userRes.data.email
                    groups = $groups.data | ForEach-Object { $_.group.domainIdentifier }
                }
                $this.CacheUserData()
            } catch {
                Write-Warning "Nutzerdaten konnten nicht abgefragt werden."
                throw "Could not load user data: $_"
            }
        }
    }

    [void] CacheUserData() {
        $this.User | ConvertTo-Json | Set-Content -Path $this.CachePath
    }

    [bool] UserHasAccess([string[]]$allowedGroups) {
        if (-not $this.User -or -not $this.User.groups) {
            return $false
        }
        foreach ($group in $AllowedGroups) {
            if ($this.User.Groups -contains $group) {
                return $true
            }
        }
        return $false
    }
}
