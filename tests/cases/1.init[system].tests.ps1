@(
    @{
        Name = "Exit if incorrect subdomain provided (user mode: prompt loop)"
        ExpectedMessage = "Wrong subdomain provided in test mode"
        ExpectedExitCode = 0
        HostInputs = @{
            Subdomain = "klwel"
        }
    },
    @{
        Name = "Exit if incorrect token (user mode: prompt loop)"
        ExpectedMessage = "Nicht autorisiert"
        ExpectedExitCode = 0
        HostInputs = @{
            Subdomain = "bgh"
            LoginToken = "abc"
        }
    },
    @{
        Name = "Success if correct token"
        ExpectedMessage = "Das CLI ist jetzt fertig konfiguriert"
        ExpectedExitCode = 0
        HostInputs = @{
            Subdomain = "bgh"
            LoginToken = $env:CT_LOGIN_TOKEN
        }
    }
)