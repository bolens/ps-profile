@{
    # Required PowerShell modules
    Modules = @{
        # Development and testing modules
        'PSScriptAnalyzer'      = @{
            Version     = '1.21.0'
            Description = 'PowerShell script analyzer for linting and code quality'
            Required    = $true
        }
        'Pester'                = @{
            Version     = '5.0.0'
            Description = 'PowerShell testing framework'
            Required    = $true
        }
        
        # Optional but recommended modules
        'PowerShell-Beautifier' = @{
            Version     = '1.2.0'
            Description = 'Code formatter for PowerShell scripts'
            Required    = $false
        }
    }
}

