@(
    @{
        Name = "Exit if incorrect subdomain (user mode: prompt loop)"
        ExpectedOutputs = @("Wrong subdomain provided in test mode")
        ExpectedExitCode = 1
        HostInputs = @{
            Subdomain = "klwel"
        }
    },
    @{
        Name = "Exit if incorrect token (user mode: prompt loop)"
        ExpectedOutputs = @("Nicht autorisiert")
        ExpectedExitCode = 1
        HostInputs = @{
            Subdomain = "bgh"
            LoginToken = "abc"
        }
    },
    @{
        Name = "Success if correct token"
        ExpectedOutputs = @("Das CLI ist jetzt fertig konfiguriert")
        ExpectedExitCode = 0
        HostInputs = @{
            Subdomain = "bgh"
            LoginToken = ($env:CT_LOGIN_TOKEN)
        }
    }
)