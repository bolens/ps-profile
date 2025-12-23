@{
    # Code Quality Tools
    ExternalTools = @{
        'cspell'           = @{
            Version        = '9.4.0'
            Description    = 'Spell checker for code and documentation'
            Required       = $false
            InstallCommand = 'pnpm install'
            Note           = 'Declared in package.json devDependencies'
        }
        'markdownlint-cli' = @{
            Version        = '0.46.0'
            Description    = 'Markdown linting tool'
            Required       = $false
            InstallCommand = 'pnpm install'
            Note           = 'Declared in package.json devDependencies'
        }
        'git-cliff'        = @{
            Version        = '2.0.0'
            Description    = 'Changelog generator from git history'
            Required       = $false
            InstallCommand = 'cargo install git-cliff'
        }
    }
}

