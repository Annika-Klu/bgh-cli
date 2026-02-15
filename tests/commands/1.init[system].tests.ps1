@(
    @{
        Name = "Fail if incorrect subdomain (user mode: prompt loop)"
        ExpectedOutputs = @("Wrong subdomain provided in test mode", "401")
        ExpectedExitCode = 1
        HostInputs = @{
            Subdomain = "klwel"
        }
    },
    @{
        Name = "Fail if incorrect token (user mode: prompt loop)"
        ExpectedOutputs = @("Invalid token provided in test mode", "401")
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