@{
    # Security Tools
    ExternalTools = @{
        'gitleaks'    = @{
            Version        = 'latest'
            Description    = 'Git secrets scanner'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install gitleaks'
                Linux   = 'See: https://github.com/gitleaks/gitleaks'
                MacOS   = 'brew install gitleaks'
            }
        }
        'trufflehog'  = @{
            Version        = 'latest'
            Description    = 'Secrets scanner with pattern detection'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install trufflehog'
                Linux   = 'See: https://github.com/trufflesecurity/trufflehog'
                MacOS   = 'brew install trufflehog'
            }
        }
        'osv-scanner' = @{
            Version        = 'latest'
            Description    = 'Vulnerability scanner using OSV database'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install osv-scanner'
                Linux   = 'See: https://google.github.io/osv-scanner/installation/'
                MacOS   = 'brew install osv-scanner'
            }
        }
        'yara'        = @{
            Version        = 'latest'
            Description    = 'Pattern matching for malware detection'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install yara'
                Linux   = 'apt install yara'
                MacOS   = 'brew install yara'
            }
        }
        'clamav'      = @{
            Version        = 'latest'
            Description    = 'Antivirus scanner'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install clamav'
                Linux   = 'apt install clamav'
                MacOS   = 'brew install clamav'
            }
        }
        'dangerzone'  = @{
            Version        = 'latest'
            Description    = 'Safe document viewing and conversion'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install dangerzone'
                Linux   = 'See: https://github.com/firstlookmedia/dangerzone'
                MacOS   = 'brew install dangerzone'
            }
        }
    }
}

