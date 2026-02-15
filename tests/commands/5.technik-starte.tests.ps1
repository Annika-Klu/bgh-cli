@(
    @{
        Name = "Should exit without device arg 'auf'"
        ExpectedExitCode = 0
        ExpectedOutputs = @("Pflichtargument 'auf' (pc oder notebook) fehlt")
    },
    @{
        Name = "Should exit if device arg 'auf' invalid"
        ExpectedExitCode = 0
        ExpectedOutputs = @("Ungültiger Wert 'bla' für 'auf'")
        Arguments = @{
            auf = "bla"
        }
    }
)
