@{
    # PowerShell version requirements
    PowerShellVersion    = '7.0.0'
    
    # Required PowerShell modules
    Modules              = @{
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
    
    # External tools (not PowerShell modules)
    ExternalTools        = @{
        'cspell'           = @{
            Version        = '9.0.0'
            Description    = 'Spell checker for code and documentation'
            Required       = $false
            InstallCommand = 'npm install -g cspell@9'
        }
        'markdownlint-cli' = @{
            Version        = '0.40.0'
            Description    = 'Markdown linting tool'
            Required       = $false
            InstallCommand = 'npm install -g markdownlint-cli@0.40.0'
        }
        'git-cliff'        = @{
            Version        = '2.0.0'
            Description    = 'Changelog generator from git history'
            Required       = $false
            InstallCommand = 'cargo install git-cliff'
        }
    }
    
    # Platform-specific requirements
    PlatformRequirements = @{
        Windows = @{
            PowerShell = '7.0.0'
            MinimumOS  = 'Windows 10'
        }
        Linux   = @{
            PowerShell = '7.0.0'
            MinimumOS  = 'Ubuntu 18.04 or equivalent'
        }
        MacOS   = @{
            PowerShell = '7.0.0'
            MinimumOS  = 'macOS 10.15'
        }
    }
}

