@(
    @{
        Name = "Should exit without arguments"
        ExpectedExitCode = 0
        ExpectedOutputs = @("Fehlendes Argument")
    },
    @{
        Name = "Should exit with incorrect arguments"
        ExpectedExitCode = 0
        ExpectedOutputs = @("Falsches Argument")
        Arguments = @{
            von = "bla"
        }
    },
    @{
        Name = "Should exit with only one correct argument"
        ExpectedExitCode = 0
        ExpectedOutputs = @("Fehlendes Argument")
        Arguments = @{
            von = "lokal"
        }
    },
    @{
        Name = "Should exit if arguments are equal"
        ExpectedExitCode = 0
        ExpectedOutputs = @("dürfen nicht identisch sein")
        Arguments = @{
            von = "lokal"
            nach = "lokal"
        }
    }
)
