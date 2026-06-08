# ===============================================
# ToolInstallRegistry.ps1
# Tool installation method registry and fallback chains
# ===============================================
# Depends on: MissingToolWarnings.ps1 (platform utilities)
# ===============================================

<#
.SYNOPSIS
    Tool installation method registry and preference-aware fallback chains.

.DESCRIPTION
    Provides the core registry and resolution functions used by InstallHintResolver.ps1
    and Write-MissingToolWarning to generate accurate install hints:
    - Get-ToolInstallMethodRegistry: hashtable of tool -> install method mappings
    - Get-ToolSpecificInstallMethod: look up a single tool's preferred method
    - Test-CommandAvailable: thin wrapper around Get-Command with error suppression
    - Get-InstallMethodFallbackChain: ordered fallback list for a tool type
    - Get-SystemPackageManagerFallbackChain: platform-aware package manager order
    - Test-PreferenceAwareInstallPreferences: validate current env-var preferences
    - Set-PreferenceAwareInstallPreferences: set env-var preferences interactively
    - Show-MissingToolWarningsTable: display a summary table of all known tools

.NOTES
    Load before InstallHintResolver.ps1.
#>

<#
.SYNOPSIS
    Tool-specific installation method registry.
.DESCRIPTION
    Returns a hashtable mapping tool names to their preferred installation methods
    across different platforms and package managers.
.OUTPUTS
    System.Collections.Hashtable
#>
function global:Get-ToolInstallMethodRegistry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    # Registry structure: ToolName -> Platform -> PackageManager -> InstallCommand
    return @{
        'pnpm'           = @{
            'Windows' = @{
                'scoop'      = 'scoop install pnpm'
                'winget'     = 'winget install pnpm'
                'npm'        = 'npm install -g pnpm'
                'chocolatey' = 'choco install pnpm -y'
            }
            'Linux'   = @{
                'npm' = 'npm install -g pnpm'
                'apt' = 'sudo apt install pnpm'
                'yum' = 'sudo yum install pnpm'
                'dnf' = 'sudo dnf install pnpm'
            }
            'macOS'   = @{
                'homebrew' = 'brew install pnpm'
                'npm'      = 'npm install -g pnpm'
            }
        }
        'uv'             = @{
            'Windows' = @{
                'scoop'  = 'scoop install uv'
                'pip'    = 'pip install uv'
                'winget' = 'winget install astral-sh.uv'
            }
            'Linux'   = @{
                'curl' = 'curl -LsSf https://astral.sh/uv/install.sh | sh'
                'pip'  = 'pip install uv'
            }
            'macOS'   = @{
                'homebrew' = 'brew install uv'
                'pip'      = 'pip install uv'
            }
        }
        'poetry'         = @{
            'Windows' = @{
                'scoop' = 'scoop install poetry'
                'pip'   = 'pip install poetry'
                'uv'    = 'uv tool install poetry'
            }
            'Linux'   = @{
                'curl' = 'curl -sSL https://install.python-poetry.org | python3 -'
                'pip'  = 'pip install poetry'
            }
            'macOS'   = @{
                'homebrew' = 'brew install poetry'
                'pip'      = 'pip install poetry'
            }
        }
        'cargo-binstall' = @{
            'Windows' = @{
                'cargo' = 'cargo install cargo-binstall'
                'scoop' = 'scoop install cargo-binstall'
            }
            'Linux'   = @{
                'cargo' = 'cargo install cargo-binstall'
                'curl'  = 'curl -L --proto "=https" --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash'
            }
            'macOS'   = @{
                'cargo'    = 'cargo install cargo-binstall'
                'homebrew' = 'brew install cargo-binstall'
            }
        }
        'bd'             = @{
            'Windows' = @{
                'powershell' = 'irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 | iex'
                'npm'        = 'npm install -g @beads/bd'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'  = 'npm install -g @beads/bd'
            }
            'macOS'   = @{
                'homebrew' = 'brew tap steveyegge/beads && brew install bd'
                'curl'     = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'      = 'npm install -g @beads/bd'
            }
        }
        'beads'          = @{
            'Windows' = @{
                'powershell' = 'irm https://raw.githubusercontent.com/steveyegge/beads/main/install.ps1 | iex'
                'npm'        = 'npm install -g @beads/bd'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'  = 'npm install -g @beads/bd'
            }
            'macOS'   = @{
                'homebrew' = 'brew tap steveyegge/beads && brew install bd'
                'curl'     = 'curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash'
                'npm'      = 'npm install -g @beads/bd'
            }
        }
        'sqlite3'        = @{
            'Windows' = @{
                'scoop'      = 'scoop install sqlite'
                'winget'     = 'winget install sqlite'
                'chocolatey' = 'choco install sqlite -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install sqlite3'
                'dnf'    = 'sudo dnf install sqlite'
                'yum'    = 'sudo yum install sqlite'
                'pacman' = 'sudo pacman -S sqlite'
            }
            'macOS'   = @{
                'homebrew' = 'brew install sqlite'
            }
        }
        'aws'            = @{
            'Windows' = @{
                'scoop'      = 'scoop install aws'
                'winget'     = 'winget install Amazon.AWSCLI'
                'chocolatey' = 'choco install awscli -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install awscli'
                'dnf'    = 'sudo dnf install awscli'
                'yum'    = 'sudo yum install awscli'
                'pacman' = 'sudo pacman -S aws-cli'
            }
            'macOS'   = @{
                'homebrew' = 'brew install awscli'
            }
        }
        'azure-cli'      = @{
            'Windows' = @{
                'scoop'      = 'scoop install azure-cli'
                'winget'     = 'winget install Microsoft.AzureCLI'
                'chocolatey' = 'choco install azure-cli -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install azure-cli'
                'dnf'    = 'sudo dnf install azure-cli'
                'yum'    = 'sudo yum install azure-cli'
                'pacman' = 'sudo pacman -S azure-cli'
            }
            'macOS'   = @{
                'homebrew' = 'brew install azure-cli'
            }
        }
        'azure-developer-cli' = @{
            'Windows' = @{
                'scoop'      = 'scoop install azure-developer-cli'
                'winget'     = 'winget install Microsoft.Azd'
                'chocolatey' = 'choco install azd -y'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://aka.ms/install-azd.sh | bash'
            }
            'macOS'   = @{
                'homebrew' = 'brew install azure/azd/azd'
            }
        }
        'gcloud'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install gcloud'
                'chocolatey' = 'choco install gcloudsdk -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install google-cloud-cli'
                'dnf'    = 'sudo dnf install google-cloud-cli'
                'yum'    = 'sudo yum install google-cloud-cli'
                'pacman' = 'sudo pacman -S google-cloud-sdk'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask google-cloud-sdk'
            }
        }
        'terraform'      = @{
            'Windows' = @{
                'scoop'      = 'scoop install terraform'
                'winget'     = 'winget install Hashicorp.Terraform'
                'chocolatey' = 'choco install terraform -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install terraform'
                'dnf'    = 'sudo dnf install terraform'
                'yum'    = 'sudo yum install terraform'
                'pacman' = 'sudo pacman -S terraform'
            }
            'macOS'   = @{
                'homebrew' = 'brew install terraform'
            }
        }
        'gh'             = @{
            'Windows' = @{
                'scoop'      = 'scoop install gh'
                'winget'     = 'winget install GitHub.cli'
                'chocolatey' = 'choco install gh -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install gh'
                'dnf'    = 'sudo dnf install gh'
                'yum'    = 'sudo yum install gh'
                'pacman' = 'sudo pacman -S github-cli'
            }
            'macOS'   = @{
                'homebrew' = 'brew install gh'
            }
        }
        'kubectl'        = @{
            'Windows' = @{
                'scoop'      = 'scoop install kubectl'
                'winget'     = 'winget install Kubernetes.kubectl'
                'chocolatey' = 'choco install kubernetes-cli -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install kubectl'
                'dnf'    = 'sudo dnf install kubectl'
                'yum'    = 'sudo yum install kubectl'
                'pacman' = 'sudo pacman -S kubectl'
            }
            'macOS'   = @{
                'homebrew' = 'brew install kubectl'
            }
        }
        'minikube'       = @{
            'Windows' = @{
                'scoop'      = 'scoop install minikube'
                'winget'     = 'winget install Kubernetes.minikube'
                'chocolatey' = 'choco install minikube -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install minikube'
                'dnf'    = 'sudo dnf install minikube'
                'yum'    = 'sudo yum install minikube'
                'pacman' = 'sudo pacman -S minikube'
            }
            'macOS'   = @{
                'homebrew' = 'brew install minikube'
            }
        }
        'helm'           = @{
            'Windows' = @{
                'scoop'      = 'scoop install helm'
                'winget'     = 'winget install Helm.Helm'
                'chocolatey' = 'choco install kubernetes-helm -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install helm'
                'dnf'    = 'sudo dnf install helm'
                'yum'    = 'sudo yum install helm'
                'pacman' = 'sudo pacman -S helm'
            }
            'macOS'   = @{
                'homebrew' = 'brew install helm'
            }
        }
        'go'             = @{
            'Windows' = @{
                'scoop'      = 'scoop install go'
                'winget'     = 'winget install GoLang.Go'
                'chocolatey' = 'choco install golang -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install golang-go'
                'dnf'    = 'sudo dnf install golang'
                'yum'    = 'sudo yum install golang'
                'pacman' = 'sudo pacman -S go'
            }
            'macOS'   = @{
                'homebrew' = 'brew install go'
            }
        }
        'deno'           = @{
            'Windows' = @{
                'scoop'      = 'scoop install deno'
                'winget'     = 'winget install DenoLand.Deno'
                'chocolatey' = 'choco install deno -y'
            }
            'Linux'   = @{
                'curl'   = 'curl -fsSL https://deno.land/install.sh | sh'
                'apt'    = 'sudo apt install deno'
                'pacman' = 'sudo pacman -S deno'
            }
            'macOS'   = @{
                'homebrew' = 'brew install deno'
                'curl'     = 'curl -fsSL https://deno.land/install.sh | sh'
            }
        }
        'rustup'         = @{
            'Windows' = @{
                'scoop' = 'scoop install rustup'
            }
            'Linux'   = @{
                'curl' = 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh'
            }
            'macOS'   = @{
                'homebrew' = 'brew install rustup-init'
                'curl'     = 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh'
            }
        }
        'dotnet-sdk'     = @{
            'Windows' = @{
                'scoop'      = 'scoop install dotnet-sdk'
                'winget'     = 'winget install Microsoft.DotNet.SDK.8'
                'chocolatey' = 'choco install dotnet-sdk -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install dotnet-sdk-8.0'
                'dnf'    = 'sudo dnf install dotnet-sdk-8.0'
                'yum'    = 'sudo yum install dotnet-sdk-8.0'
                'pacman' = 'sudo pacman -S dotnet-sdk'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask dotnet-sdk'
            }
        }
        'ripgrep'        = @{
            'Windows' = @{
                'scoop'      = 'scoop install ripgrep'
                'winget'     = 'winget install BurntSushi.ripgrep.MSVC'
                'chocolatey' = 'choco install ripgrep -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install ripgrep'
                'dnf'    = 'sudo dnf install ripgrep'
                'yum'    = 'sudo yum install ripgrep'
                'pacman' = 'sudo pacman -S ripgrep'
            }
            'macOS'   = @{
                'homebrew' = 'brew install ripgrep'
            }
        }
        'rclone'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install rclone'
                'winget'     = 'winget install Rclone.Rclone'
                'chocolatey' = 'choco install rclone -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install rclone'
                'dnf'    = 'sudo dnf install rclone'
                'yum'    = 'sudo yum install rclone'
                'pacman' = 'sudo pacman -S rclone'
            }
            'macOS'   = @{
                'homebrew' = 'brew install rclone'
            }
        }
        'lazydocker'     = @{
            'Windows' = @{
                'scoop'      = 'scoop install lazydocker'
                'chocolatey' = 'choco install lazydocker -y'
            }
            'Linux'   = @{
                'curl'   = 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
                'pacman' = 'sudo pacman -S lazydocker'
            }
            'macOS'   = @{
                'homebrew' = 'brew install lazydocker'
            }
        }
        'tailscale'      = @{
            'Windows' = @{
                'scoop'      = 'scoop install tailscale'
                'winget'     = 'winget install Tailscale.Tailscale'
                'chocolatey' = 'choco install tailscale -y'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://tailscale.com/install.sh | sh'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask tailscale'
            }
        }
        'minio-client'   = @{
            'Windows' = @{
                'scoop'      = 'scoop install minio-client'
                'chocolatey' = 'choco install minio-client -y'
            }
            'Linux'   = @{
                'curl'   = 'curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o mc && chmod +x mc && sudo mv mc /usr/local/bin/'
                'pacman' = 'sudo pacman -S minio-client'
            }
            'macOS'   = @{
                'homebrew' = 'brew install minio/stable/mc'
            }
        }
        'mise'           = @{
            'Windows' = @{
                'scoop' = 'scoop install mise'
            }
            'Linux'   = @{
                'curl' = 'curl https://mise.run | sh'
            }
            'macOS'   = @{
                'homebrew' = 'brew install mise'
                'curl'     = 'curl https://mise.run | sh'
            }
        }
        'navi'           = @{
            'Windows' = @{
                'scoop' = 'scoop install navi'
            }
            'Linux'   = @{
                'cargo'  = 'cargo install navi'
                'pacman' = 'sudo pacman -S navi'
            }
            'macOS'   = @{
                'homebrew' = 'brew install navi'
                'cargo'    = 'cargo install navi'
            }
        }
        'httpie'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install httpie'
                'pip'        = 'pip install httpie'
                'chocolatey' = 'choco install httpie -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install httpie'
                'dnf'    = 'sudo dnf install httpie'
                'pacman' = 'sudo pacman -S httpie'
                'pip'    = 'pip install httpie'
            }
            'macOS'   = @{
                'homebrew' = 'brew install httpie'
                'pip'      = 'pip install httpie'
            }
        }
        'bruno'          = @{
            'Windows' = @{
                'scoop'  = 'scoop install bruno'
                'winget' = 'winget install Bruno.Bruno'
            }
            'Linux'   = @{
                'snap' = 'sudo snap install bruno'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask bruno'
            }
        }
        'hurl'           = @{
            'Windows' = @{
                'scoop' = 'scoop install hurl'
                'cargo' = 'cargo install hurl'
            }
            'Linux'   = @{
                'cargo'  = 'cargo install hurl'
                'pacman' = 'sudo pacman -S hurl'
            }
            'macOS'   = @{
                'homebrew' = 'brew install hurl'
                'cargo'    = 'cargo install hurl'
            }
        }
        'insomnia'       = @{
            'Windows' = @{
                'scoop'  = 'scoop install insomnia'
                'winget' = 'winget install Insomnia.Insomnia'
            }
            'Linux'   = @{
                'snap' = 'sudo snap install insomnia'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask insomnia'
            }
        }
        'httptoolkit'    = @{
            'Windows' = @{
                'scoop'  = 'scoop install httptoolkit'
                'winget' = 'winget install HTTPToolkit.HTTPToolkit'
            }
            'Linux'   = @{
                'snap' = 'sudo snap install httptoolkit'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask httptoolkit'
            }
        }
        'maven'          = @{
            'Windows' = @{
                'scoop'      = 'scoop install maven'
                'chocolatey' = 'choco install maven -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install maven'
                'dnf'    = 'sudo dnf install maven'
                'yum'    = 'sudo yum install maven'
                'pacman' = 'sudo pacman -S maven'
            }
            'macOS'   = @{
                'homebrew' = 'brew install maven'
            }
        }
        'gradle'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install gradle'
                'chocolatey' = 'choco install gradle -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install gradle'
                'dnf'    = 'sudo dnf install gradle'
                'yum'    = 'sudo yum install gradle'
                'pacman' = 'sudo pacman -S gradle'
            }
            'macOS'   = @{
                'homebrew' = 'brew install gradle'
            }
        }
        'ant'            = @{
            'Windows' = @{
                'scoop'      = 'scoop install ant'
                'chocolatey' = 'choco install ant -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install ant'
                'dnf'    = 'sudo dnf install ant'
                'yum'    = 'sudo yum install ant'
                'pacman' = 'sudo pacman -S ant'
            }
            'macOS'   = @{
                'homebrew' = 'brew install ant'
            }
        }
        'dart-sdk'       = @{
            'Windows' = @{
                'scoop'  = 'scoop install dart-sdk'
                'choco'  = 'choco install dart-sdk -y'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install dart'
            }
            'macOS'   = @{
                'homebrew' = 'brew install dart'
            }
        }
        'flutter'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install flutter'
                'choco'  = 'choco install flutter -y'
            }
            'Linux'   = @{
                'snap' = 'sudo snap install flutter --classic'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask flutter'
            }
        }
        'goreleaser'     = @{
            'Windows' = @{
                'scoop' = 'scoop install goreleaser'
                'go'    = 'go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest'
            }
            'Linux'   = @{
                'go'     = 'go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest'
                'pacman' = 'sudo pacman -S goreleaser'
            }
            'macOS'   = @{
                'homebrew' = 'brew install goreleaser'
                'go'       = 'go install github.com/goreleaser/goreleaser/v2/cmd/goreleaser@latest'
            }
        }
        'golangci-lint'  = @{
            'Windows' = @{
                'scoop' = 'scoop install golangci-lint'
                'go'    = 'go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest'
            }
            'Linux'   = @{
                'go'     = 'go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest'
                'pacman' = 'sudo pacman -S golangci-lint'
            }
            'macOS'   = @{
                'homebrew' = 'brew install golangci-lint'
                'go'       = 'go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest'
            }
        }
        'git'            = @{
            'Windows' = @{
                'scoop'      = 'scoop install git'
                'winget'     = 'winget install Git.Git'
                'chocolatey' = 'choco install git -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install git'
                'dnf'    = 'sudo dnf install git'
                'yum'    = 'sudo yum install git'
                'pacman' = 'sudo pacman -S git'
            }
            'macOS'   = @{
                'homebrew' = 'brew install git'
            }
        }
        'python'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install python'
                'winget'     = 'winget install Python.Python.3.12'
                'chocolatey' = 'choco install python -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install python3'
                'dnf'    = 'sudo dnf install python3'
                'yum'    = 'sudo yum install python3'
                'pacman' = 'sudo pacman -S python'
            }
            'macOS'   = @{
                'homebrew' = 'brew install python3'
            }
        }
        'php'            = @{
            'Windows' = @{
                'scoop'      = 'scoop install php'
                'chocolatey' = 'choco install php -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install php'
                'dnf'    = 'sudo dnf install php'
                'yum'    = 'sudo yum install php'
                'pacman' = 'sudo pacman -S php'
            }
            'macOS'   = @{
                'homebrew' = 'brew install php'
            }
        }
        'composer'       = @{
            'Windows' = @{
                'scoop' = 'scoop install composer'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install composer'
                'dnf'    = 'sudo dnf install composer'
                'pacman' = 'sudo pacman -S composer'
            }
            'macOS'   = @{
                'homebrew' = 'brew install composer'
            }
        }
        'ruby'           = @{
            'Windows' = @{
                'scoop'      = 'scoop install ruby'
                'chocolatey' = 'choco install ruby -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install ruby-full'
                'dnf'    = 'sudo dnf install ruby'
                'yum'    = 'sudo yum install ruby'
                'pacman' = 'sudo pacman -S ruby'
            }
            'macOS'   = @{
                'homebrew' = 'brew install ruby'
            }
        }
        'kotlin'         = @{
            'Windows' = @{ 'scoop' = 'scoop install kotlin' }
            'Linux'   = @{
                'apt'    = 'sudo apt install kotlin'
                'pacman' = 'sudo pacman -S kotlin'
            }
            'macOS'   = @{ 'homebrew' = 'brew install kotlin' }
        }
        'scala'          = @{
            'Windows' = @{ 'scoop' = 'scoop install scala' }
            'Linux'   = @{
                'apt'    = 'sudo apt install scala'
                'pacman' = 'sudo pacman -S scala'
            }
            'macOS'   = @{ 'homebrew' = 'brew install scala' }
        }
        'elixir'         = @{
            'Windows' = @{ 'scoop' = 'scoop install elixir' }
            'Linux'   = @{
                'apt'    = 'sudo apt install elixir'
                'pacman' = 'sudo pacman -S elixir'
            }
            'macOS'   = @{ 'homebrew' = 'brew install elixir' }
        }
        'docker'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install docker'
                'winget'     = 'winget install Docker.DockerDesktop'
                'chocolatey' = 'choco install docker-desktop -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install docker.io'
                'dnf'    = 'sudo dnf install docker'
                'yum'    = 'sudo yum install docker'
                'pacman' = 'sudo pacman -S docker'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask docker'
            }
        }
        'podman'         = @{
            'Windows' = @{ 'scoop' = 'scoop install podman' }
            'Linux'   = @{
                'apt'    = 'sudo apt install podman'
                'dnf'    = 'sudo dnf install podman'
                'yum'    = 'sudo yum install podman'
                'pacman' = 'sudo pacman -S podman'
            }
            'macOS'   = @{ 'homebrew' = 'brew install podman' }
        }
        'fzf'            = @{
            'Windows' = @{ 'scoop' = 'scoop install fzf'; 'chocolatey' = 'choco install fzf -y' }
            'Linux'   = @{
                'apt' = 'sudo apt install fzf'; 'dnf' = 'sudo dnf install fzf'
                'yum' = 'sudo yum install fzf'; 'pacman' = 'sudo pacman -S fzf'
            }
            'macOS'   = @{ 'homebrew' = 'brew install fzf' }
        }
        'eza'            = @{
            'Windows' = @{ 'scoop' = 'scoop install eza' }
            'Linux'   = @{
                'apt' = 'sudo apt install eza'; 'pacman' = 'sudo pacman -S eza'
            }
            'macOS'   = @{ 'homebrew' = 'brew install eza' }
        }
        'procs'          = @{
            'Windows' = @{ 'scoop' = 'scoop install procs' }
            'Linux'   = @{
                'apt' = 'sudo apt install procs'; 'pacman' = 'sudo pacman -S procs'
            }
            'macOS'   = @{ 'homebrew' = 'brew install procs' }
        }
        'dust'           = @{
            'Windows' = @{ 'scoop' = 'scoop install dust' }
            'Linux'   = @{
                'apt' = 'sudo apt install du-dust'; 'pacman' = 'sudo pacman -S dust'
            }
            'macOS'   = @{ 'homebrew' = 'brew install dust' }
        }
        'bottom'         = @{
            'Windows' = @{ 'scoop' = 'scoop install bottom' }
            'Linux'   = @{
                'apt' = 'sudo apt install bottom'; 'pacman' = 'sudo pacman -S bottom'
            }
            'macOS'   = @{ 'homebrew' = 'brew install bottom' }
        }
        'jq'             = @{
            'Windows' = @{ 'scoop' = 'scoop install jq'; 'chocolatey' = 'choco install jq -y' }
            'Linux'   = @{
                'apt' = 'sudo apt install jq'; 'dnf' = 'sudo dnf install jq'
                'yum' = 'sudo yum install jq'; 'pacman' = 'sudo pacman -S jq'
            }
            'macOS'   = @{ 'homebrew' = 'brew install jq' }
        }
        'yq'             = @{
            'Windows' = @{ 'scoop' = 'scoop install yq' }
            'Linux'   = @{
                'apt' = 'sudo apt install yq'; 'pacman' = 'sudo pacman -S go-yq'
            }
            'macOS'   = @{ 'homebrew' = 'brew install yq' }
        }
        'ngrok'          = @{
            'Windows' = @{ 'scoop' = 'scoop install ngrok'; 'chocolatey' = 'choco install ngrok -y' }
            'Linux'   = @{
                'apt' = 'sudo apt install ngrok'; 'pacman' = 'sudo pacman -S ngrok'
            }
            'macOS'   = @{ 'homebrew' = 'brew install ngrok/ngrok/ngrok' }
        }
        'pixi'           = @{
            'Windows' = @{ 'scoop' = 'scoop install pixi' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://pixi.sh/install.sh | bash' }
            'macOS'   = @{
                'homebrew' = 'brew install pixi'
                'curl'     = 'curl -fsSL https://pixi.sh/install.sh | bash'
            }
        }
        'ollama'         = @{
            'Windows' = @{ 'scoop' = 'scoop install ollama' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://ollama.com/install.sh | sh' }
            'macOS'   = @{ 'homebrew' = 'brew install ollama' }
        }
        'firebase-tools' = @{
            'Windows' = @{
                'npm'   = 'npm install -g firebase-tools'
                'scoop' = 'scoop install firebase-tools'
            }
            'Linux'   = @{ 'npm' = 'npm install -g firebase-tools' }
            'macOS'   = @{
                'npm'      = 'npm install -g firebase-tools'
                'homebrew' = 'brew install firebase-cli'
            }
        }
        'julia'          = @{
            'Windows' = @{ 'scoop' = 'scoop install julia' }
            'Linux'   = @{
                'apt' = 'sudo apt install julia'; 'pacman' = 'sudo pacman -S julia'
            }
            'macOS'   = @{ 'homebrew' = 'brew install julia' }
        }
        'nim'            = @{
            'Windows' = @{ 'scoop' = 'scoop install nim' }
            'Linux'   = @{
                'apt' = 'sudo apt install nim'; 'pacman' = 'sudo pacman -S nim'
            }
            'macOS'   = @{ 'homebrew' = 'brew install nim' }
        }
        'swift'          = @{
            'Windows' = @{ 'scoop' = 'scoop install swift' }
            'Linux'   = @{ 'apt' = 'sudo apt install swift' }
            'macOS'   = @{ 'homebrew' = 'brew install swift' }
        }
        'miniconda3'     = @{
            'Windows' = @{
                'scoop' = 'scoop install miniconda3'
            }
            'Linux'   = @{
                'curl' = 'curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && bash miniconda.sh'
            }
            'macOS'   = @{
                'homebrew' = 'brew install --cask miniconda'
            }
        }
        'nuget'          = @{
            'Windows' = @{
                'scoop'      = 'scoop install nuget'
                'chocolatey' = 'choco install nuget.commandline -y'
                'winget'     = 'winget install Microsoft.NuGet'
            }
            'Linux'   = @{
                'dotnet' = 'dotnet tool install -g NuGet.CommandLine'
            }
            'macOS'   = @{
                'dotnet' = 'dotnet tool install -g NuGet.CommandLine'
            }
        }
        'dbeaver'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install dbeaver'
                'winget' = 'winget install DBeaver.DBeaver.Community'
            }
            'Linux'   = @{
                'snap' = 'sudo snap install dbeaver-ce'
                'apt'  = 'sudo apt install dbeaver-ce'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask dbeaver-community' }
        }
        'tableplus'      = @{
            'Windows' = @{ 'scoop' = 'scoop install tableplus' }
            'Linux'   = @{ 'snap' = 'sudo snap install tableplus' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask tableplus' }
        }
        'mongodb-compass' = @{
            'Windows' = @{
                'scoop'  = 'scoop install mongodb-compass'
                'winget' = 'winget install MongoDB.Compass.Community'
            }
            'Linux'   = @{ 'snap' = 'sudo snap install mongodb-compass' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask mongodb-compass' }
        }
        'hasura-cli'     = @{
            'Windows' = @{ 'scoop' = 'scoop install hasura-cli' }
            'Linux'   = @{ 'curl' = 'curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install hasura-cli' }
        }
        'supabase-beta'  = @{
            'Windows' = @{ 'scoop' = 'scoop install supabase-beta' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://raw.githubusercontent.com/supabase/cli/main/install.sh | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install supabase/tap/supabase' }
        }
        'ffmpeg'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install ffmpeg'
                'chocolatey' = 'choco install ffmpeg -y'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install ffmpeg'; 'dnf' = 'sudo dnf install ffmpeg'
                'yum' = 'sudo yum install ffmpeg'; 'pacman' = 'sudo pacman -S ffmpeg'
            }
            'macOS'   = @{ 'homebrew' = 'brew install ffmpeg' }
        }
        'pandoc'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install pandoc'
                'chocolatey' = 'choco install pandoc -y'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install pandoc'; 'dnf' = 'sudo dnf install pandoc'
                'yum' = 'sudo yum install pandoc'; 'pacman' = 'sudo pacman -S pandoc'
            }
            'macOS'   = @{ 'homebrew' = 'brew install pandoc' }
        }
        'imagemagick'    = @{
            'Windows' = @{ 'scoop' = 'scoop install imagemagick' }
            'Linux'   = @{
                'apt' = 'sudo apt install imagemagick'; 'pacman' = 'sudo pacman -S imagemagick'
            }
            'macOS'   = @{ 'homebrew' = 'brew install imagemagick' }
        }
        'xz'             = @{
            'Windows' = @{ 'scoop' = 'scoop install xz' }
            'Linux'   = @{
                'apt' = 'sudo apt install xz-utils'; 'dnf' = 'sudo dnf install xz'
                'yum' = 'sudo yum install xz'; 'pacman' = 'sudo pacman -S xz'
            }
            'macOS'   = @{ 'homebrew' = 'brew install xz' }
        }
        'lz4'            = @{
            'Windows' = @{ 'scoop' = 'scoop install lz4' }
            'Linux'   = @{
                'apt' = 'sudo apt install lz4'; 'pacman' = 'sudo pacman -S lz4'
            }
            'macOS'   = @{ 'homebrew' = 'brew install lz4' }
        }
        'zstd'           = @{
            'Windows' = @{ 'scoop' = 'scoop install zstd' }
            'Linux'   = @{
                'apt' = 'sudo apt install zstd'; 'pacman' = 'sudo pacman -S zstd'
            }
            'macOS'   = @{ 'homebrew' = 'brew install zstd' }
        }
        'pipx'           = @{
            'Windows' = @{
                'scoop' = 'scoop install pipx'
                'pip'   = 'pip install pipx'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install pipx'; 'pip' = 'pip install pipx'
                'pacman' = 'sudo pacman -S python-pipx'
            }
            'macOS'   = @{
                'homebrew' = 'brew install pipx'
                'pip'      = 'pip install pipx'
            }
        }
        'rye'            = @{
            'Windows' = @{ 'scoop' = 'scoop install rye' }
            'Linux'   = @{ 'curl' = 'curl -sSf https://rye-up.com/get | bash' }
            'macOS'   = @{
                'homebrew' = 'brew install rye'
                'curl'     = 'curl -sSf https://rye-up.com/get | bash'
            }
        }
        'terragrunt'     = @{
            'Windows' = @{
                'scoop' = 'scoop install terragrunt'
                'winget' = 'winget install Gruntwork.Terragrunt'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install terragrunt'; 'pacman' = 'sudo pacman -S terragrunt'
            }
            'macOS'   = @{ 'homebrew' = 'brew install terragrunt' }
        }
        'opentofu'       = @{
            'Windows' = @{
                'scoop' = 'scoop install opentofu'
                'winget' = 'winget install OpenTofu.Tofu'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install opentofu'; 'pacman' = 'sudo pacman -S opentofu'
            }
            'macOS'   = @{ 'homebrew' = 'brew install opentofu' }
        }
        'pulumi'         = @{
            'Windows' = @{
                'scoop' = 'scoop install pulumi'
                'winget' = 'winget install Pulumi.Pulumi'
            }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://get.pulumi.com | sh' }
            'macOS'   = @{
                'homebrew' = 'brew install pulumi'
                'curl'     = 'curl -fsSL https://get.pulumi.com | sh'
            }
        }
        'ansible'        = @{
            'Windows' = @{
                'pip'   = 'pip install ansible'
                'scoop' = 'scoop install ansible'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install ansible'; 'dnf' = 'sudo dnf install ansible'
                'pacman' = 'sudo pacman -S ansible'
            }
            'macOS'   = @{ 'homebrew' = 'brew install ansible' }
        }
        'k9s'            = @{
            'Windows' = @{
                'scoop' = 'scoop install k9s'
                'winget' = 'winget install Derailed.k9s'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install k9s'; 'pacman' = 'sudo pacman -S k9s'
            }
            'macOS'   = @{ 'homebrew' = 'brew install k9s' }
        }
        'doppler'        = @{
            'Windows' = @{
                'scoop' = 'scoop install doppler'
                'winget' = 'winget install Doppler.doppler'
            }
            'Linux'   = @{ 'curl' = 'curl -Ls --tlsv1.2 --proto "=https" https://cli.doppler.com/install.sh | sh' }
            'macOS'   = @{ 'homebrew' = 'brew install dopplerhq/cli/doppler' }
        }
        'heroku-cli'     = @{
            'Windows' = @{
                'scoop' = 'scoop install heroku-cli'
                'winget' = 'winget install Heroku.HerokuCLI'
            }
            'Linux'   = @{
                'curl' = 'curl https://cli-assets.heroku.com/install.sh | sh'
            }
            'macOS'   = @{ 'homebrew' = 'brew tap heroku/brew && brew install heroku' }
        }
        'vercel'         = @{
            'Windows' = @{ 'npm' = 'npm install -g vercel' }
            'Linux'   = @{ 'npm' = 'npm install -g vercel' }
            'macOS'   = @{ 'npm' = 'npm install -g vercel' }
        }
        'netlify'        = @{
            'Windows' = @{ 'npm' = 'npm install -g netlify-cli' }
            'Linux'   = @{ 'npm' = 'npm install -g netlify-cli' }
            'macOS'   = @{ 'npm' = 'npm install -g netlify-cli' }
        }
        'flyctl'         = @{
            'Windows' = @{
                'scoop' = 'scoop install flyctl'
                'winget' = 'winget install Flyio.flyctl'
            }
            'Linux'   = @{ 'curl' = 'curl -L https://fly.io/install.sh | sh' }
            'macOS'   = @{ 'homebrew' = 'brew install flyctl' }
        }
        'asdf'           = @{
            'Windows' = @{ 'scoop' = 'scoop install asdf' }
            'Linux'   = @{ 'git' = 'git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0' }
            'macOS'   = @{ 'homebrew' = 'brew install asdf' }
        }
        'volta'          = @{
            'Windows' = @{ 'scoop' = 'scoop install volta' }
            'Linux'   = @{ 'curl' = 'curl https://get.volta.sh | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install volta' }
        }
        'sbt'            = @{
            'Windows' = @{ 'scoop' = 'scoop install sbt' }
            'Linux'   = @{
                'apt' = 'sudo apt install sbt'; 'pacman' = 'sudo pacman -S sbt'
            }
            'macOS'   = @{ 'homebrew' = 'brew install sbt' }
        }
        'nuxi'           = @{
            'Windows' = @{ 'npm' = 'npm install -g nuxi' }
            'Linux'   = @{ 'npm' = 'npm install -g nuxi' }
            'macOS'   = @{ 'npm' = 'npm install -g nuxi' }
        }
        'snappy'         = @{
            'Windows' = @{ 'scoop' = 'scoop install snappy' }
            'Linux'   = @{
                'apt' = 'sudo apt install snappy-tools'; 'pacman' = 'sudo pacman -S snappy'
            }
            'macOS'   = @{ 'homebrew' = 'brew install snappy' }
        }
        'graphicsmagick' = @{
            'Windows' = @{ 'scoop' = 'scoop install graphicsmagick' }
            'Linux'   = @{
                'apt' = 'sudo apt install graphicsmagick'; 'pacman' = 'sudo pacman -S graphicsmagick'
            }
            'macOS'   = @{ 'homebrew' = 'brew install graphicsmagick' }
        }
        'miktex'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install miktex'
                'chocolatey' = 'choco install miktex -y'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install texlive-latex-base'
                'dnf'    = 'sudo dnf install texlive-scheme-basic'
                'pacman' = 'sudo pacman -S texlive-basic'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask mactex-no-gui' }
        }
        'jadx'           = @{
            'Windows' = @{
                'scoop'  = 'scoop install jadx'
                'winget' = 'winget install Skylot.JADX'
            }
            'Linux'   = @{ 'apt' = 'sudo apt install jadx' }
            'macOS'   = @{ 'homebrew' = 'brew install jadx' }
        }
        'dnspyex'        = @{
            'Windows' = @{ 'scoop' = 'scoop install dnspyex' }
            'Linux'   = @{ 'scoop' = 'scoop install dnspyex' }
            'macOS'   = @{ 'scoop' = 'scoop install dnspyex' }
        }
        'pe-bear'        = @{
            'Windows' = @{ 'scoop' = 'scoop install pe-bear' }
            'Linux'   = @{ 'scoop' = 'scoop install pe-bear' }
            'macOS'   = @{ 'scoop' = 'scoop install pe-bear' }
        }
        'apktool'        = @{
            'Windows' = @{
                'scoop'      = 'scoop install apktool'
                'chocolatey' = 'choco install apktool -y'
            }
            'Linux'   = @{ 'apt' = 'sudo apt install apktool' }
            'macOS'   = @{ 'homebrew' = 'brew install apktool' }
        }
        'il2cppdumper'   = @{
            'Windows' = @{ 'scoop' = 'scoop install il2cppdumper' }
            'Linux'   = @{ 'scoop' = 'scoop install il2cppdumper' }
            'macOS'   = @{ 'scoop' = 'scoop install il2cppdumper' }
        }
        'yt-dlp'         = @{
            'Windows' = @{
                'scoop'      = 'scoop install yt-dlp'
                'chocolatey' = 'choco install yt-dlp -y'
                'winget'     = 'winget install yt-dlp.yt-dlp'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install yt-dlp'; 'dnf' = 'sudo dnf install yt-dlp'
                'pacman' = 'sudo pacman -S yt-dlp'
            }
            'macOS'   = @{ 'homebrew' = 'brew install yt-dlp' }
        }
        'gallery-dl'     = @{
            'Windows' = @{
                'scoop' = 'scoop install gallery-dl'
                'pip'   = 'pip install gallery-dl'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install gallery-dl'; 'pip' = 'pip install gallery-dl'
                'pacman' = 'sudo pacman -S gallery-dl'
            }
            'macOS'   = @{
                'homebrew' = 'brew install gallery-dl'
                'pip'      = 'pip install gallery-dl'
            }
        }
        'monolith'       = @{
            'Windows' = @{ 'scoop' = 'scoop install monolith' }
            'Linux'   = @{ 'cargo' = 'cargo install monolith' }
            'macOS'   = @{
                'homebrew' = 'brew install monolith'
                'cargo'    = 'cargo install monolith'
            }
        }
        'twitchdownloader' = @{
            'Windows' = @{ 'scoop' = 'scoop install twitchdownloader-cli' }
            'Linux'   = @{ 'scoop' = 'scoop install twitchdownloader-cli' }
            'macOS'   = @{ 'scoop' = 'scoop install twitchdownloader-cli' }
        }
        'wireshark'      = @{
            'Windows' = @{
                'scoop'      = 'scoop install wireshark'
                'chocolatey' = 'choco install wireshark -y'
                'winget'     = 'winget install WiresharkFoundation.Wireshark'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install wireshark'; 'dnf' = 'sudo dnf install wireshark-cli'
                'pacman' = 'sudo pacman -S wireshark-cli'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask wireshark' }
        }
        'sniffnet'       = @{
            'Windows' = @{ 'scoop' = 'scoop install sniffnet' }
            'Linux'   = @{ 'cargo' = 'cargo install sniffnet' }
            'macOS'   = @{
                'homebrew' = 'brew install sniffnet'
                'cargo'    = 'cargo install sniffnet'
            }
        }
        'trippy'         = @{
            'Windows' = @{ 'scoop' = 'scoop install trippy' }
            'Linux'   = @{ 'cargo' = 'cargo install trippy' }
            'macOS'   = @{
                'homebrew' = 'brew install trippy'
                'cargo'    = 'cargo install trippy'
            }
        }
        'nali'           = @{
            'Windows' = @{ 'scoop' = 'scoop install nali' }
            'Linux'   = @{ 'go' = 'go install github.com/zu1k/nali@latest' }
            'macOS'   = @{ 'homebrew' = 'brew install nali' }
        }
        'ipinfo'         = @{
            'Windows' = @{ 'scoop' = 'scoop install ipinfo-cli' }
            'Linux'   = @{
                'curl' = 'curl -Ls https://ipinfo.io/ipinfo.sh | bash'
                'go'   = 'go install github.com/ipinfo/cli@latest'
            }
            'macOS'   = @{ 'homebrew' = 'brew install ipinfo' }
        }
        'cloudflared'    = @{
            'Windows' = @{
                'scoop'  = 'scoop install cloudflared'
                'winget' = 'winget install Cloudflare.cloudflared'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install cloudflared'; 'dnf' = 'sudo dnf install cloudflared'
                'pacman' = 'sudo pacman -S cloudflared'
            }
            'macOS'   = @{ 'homebrew' = 'brew install cloudflared' }
        }
        'ntfy'           = @{
            'Windows' = @{ 'scoop' = 'scoop install ntfy' }
            'Linux'   = @{
                'curl' = 'curl -sSL https://raw.githubusercontent.com/binwiederhier/ntfy/main/install.sh | bash'
                'go'   = 'go install github.com/binwiederhier/ntfy/v2/cmd/ntfy@latest'
            }
            'macOS'   = @{ 'homebrew' = 'brew install ntfy' }
        }
        'handbrake'      = @{
            'Windows' = @{
                'scoop'  = 'scoop install handbrake-cli'
                'winget' = 'winget install HandBrake.HandBrake.CLI'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install handbrake-cli'; 'dnf' = 'sudo dnf install HandBrake-cli'
                'pacman' = 'sudo pacman -S handbrake-cli'
            }
            'macOS'   = @{ 'homebrew' = 'brew install handbrake' }
        }
        'cyanrip'        = @{
            'Windows' = @{ 'scoop' = 'scoop install cyanrip' }
            'Linux'   = @{ 'scoop' = 'scoop install cyanrip' }
            'macOS'   = @{ 'scoop' = 'scoop install cyanrip' }
        }
        'mediainfo'      = @{
            'Windows' = @{
                'scoop'      = 'scoop install mediainfo'
                'chocolatey' = 'choco install mediainfo -y'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install mediainfo'; 'dnf' = 'sudo dnf install mediainfo'
                'pacman' = 'sudo pacman -S mediainfo'
            }
            'macOS'   = @{ 'homebrew' = 'brew install mediainfo' }
        }
        'mkvtoolnix'     = @{
            'Windows' = @{
                'scoop'  = 'scoop install mkvtoolnix'
                'winget' = 'winget install MoritzBunkus.MKVToolNix'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install mkvtoolnix'; 'dnf' = 'sudo dnf install mkvtoolnix'
                'pacman' = 'sudo pacman -S mkvtoolnix-cli'
            }
            'macOS'   = @{ 'homebrew' = 'brew install mkvtoolnix' }
        }
        'postgresql'     = @{
            'Windows' = @{
                'scoop'      = 'scoop install postgresql'
                'chocolatey' = 'choco install postgresql -y'
                'winget'     = 'winget install PostgreSQL.PostgreSQL'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install postgresql-client'; 'dnf' = 'sudo dnf install postgresql'
                'pacman' = 'sudo pacman -S postgresql-libs'
            }
            'macOS'   = @{ 'homebrew' = 'brew install libpq' }
        }
        'mysql'          = @{
            'Windows' = @{
                'scoop'      = 'scoop install mysql'
                'chocolatey' = 'choco install mysql -y'
                'winget'     = 'winget install Oracle.MySQL'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install mysql-client'; 'dnf' = 'sudo dnf install mysql'
                'pacman' = 'sudo pacman -S mysql-clients'
            }
            'macOS'   = @{ 'homebrew' = 'brew install mysql-client' }
        }
        'mongosh'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install mongosh'
                'winget' = 'winget install MongoDB.Shell'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install mongodb-mongosh'; 'dnf' = 'sudo dnf install mongodb-mongosh'
                'pacman' = 'sudo pacman -S mongosh-bin'
            }
            'macOS'   = @{ 'homebrew' = 'brew install mongosh' }
        }
        'mongodb-database-tools' = @{
            'Windows' = @{
                'scoop'  = 'scoop install mongodb-database-tools'
                'chocolatey' = 'choco install mongodb-database-tools -y'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install mongodb-database-tools'; 'dnf' = 'sudo dnf install mongodb-database-tools'
            }
            'macOS'   = @{ 'homebrew' = 'brew install mongodb-database-tools' }
        }
        'vscode'         = @{
            'Windows' = @{
                'scoop'  = 'scoop install vscode'
                'winget' = 'winget install Microsoft.VisualStudioCode'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install code'; 'snap' = 'sudo snap install code'
                'pacman' = 'sudo pacman -S code'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask visual-studio-code' }
        }
        'cursor'         = @{
            'Windows' = @{
                'scoop'  = 'scoop install cursor'
                'winget' = 'winget install Anysphere.Cursor'
            }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://cursor.com/install | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask cursor' }
        }
        'neovim'         = @{
            'Windows' = @{ 'scoop' = 'scoop install neovim' }
            'Linux'   = @{
                'apt' = 'sudo apt install neovim'; 'dnf' = 'sudo dnf install neovim'
                'pacman' = 'sudo pacman -S neovim'
            }
            'macOS'   = @{ 'homebrew' = 'brew install neovim' }
        }
        'emacs'          = @{
            'Windows' = @{ 'scoop' = 'scoop install emacs' }
            'Linux'   = @{
                'apt' = 'sudo apt install emacs'; 'dnf' = 'sudo dnf install emacs'
                'pacman' = 'sudo pacman -S emacs'
            }
            'macOS'   = @{ 'homebrew' = 'brew install emacs' }
        }
        'lapce'          = @{
            'Windows' = @{ 'scoop' = 'scoop install lapce' }
            'Linux'   = @{ 'cargo' = 'cargo install lapce' }
            'macOS'   = @{ 'homebrew' = 'brew install lapce' }
        }
        'zed'            = @{
            'Windows' = @{ 'scoop' = 'scoop install zed' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://zed.dev/install.sh | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask zed' }
        }
        'tabby'          = @{
            'Windows' = @{ 'scoop' = 'scoop install tabby' }
            'Linux'   = @{ 'snap' = 'sudo snap install tabby' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask tabby' }
        }
        'wezterm'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install wezterm'
                'winget' = 'winget install wez.wezterm'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install wezterm'; 'dnf' = 'sudo dnf install wezterm'
                'pacman' = 'sudo pacman -S wezterm'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask wezterm' }
        }
        'alacritty'      = @{
            'Windows' = @{ 'scoop' = 'scoop install alacritty' }
            'Linux'   = @{
                'apt' = 'sudo apt install alacritty'; 'pacman' = 'sudo pacman -S alacritty'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask alacritty' }
        }
        'kitty'          = @{
            'Windows' = @{ 'scoop' = 'scoop install kitty' }
            'Linux'   = @{
                'apt' = 'sudo apt install kitty'; 'dnf' = 'sudo dnf install kitty'
                'pacman' = 'sudo pacman -S kitty'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask kitty' }
        }
        'tmux'           = @{
            'Windows' = @{ 'scoop' = 'scoop install tmux' }
            'Linux'   = @{
                'apt' = 'sudo apt install tmux'; 'dnf' = 'sudo dnf install tmux'
                'pacman' = 'sudo pacman -S tmux'
            }
            'macOS'   = @{ 'homebrew' = 'brew install tmux' }
        }
        'godot'          = @{
            'Windows' = @{ 'scoop' = 'scoop install godot' }
            'Linux'   = @{
                'apt' = 'sudo apt install godot3'; 'flatpak' = 'flatpak install flathub org.godotengine.Godot'
                'pacman' = 'sudo pacman -S godot'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask godot' }
        }
        'blockbench'     = @{
            'Windows' = @{ 'scoop' = 'scoop install blockbench' }
            'Linux'   = @{ 'flatpak' = 'flatpak install flathub net.blockbench.Blockbench' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask blockbench' }
        }
        'tiled'          = @{
            'Windows' = @{ 'scoop' = 'scoop install tiled' }
            'Linux'   = @{
                'apt' = 'sudo apt install tiled'; 'pacman' = 'sudo pacman -S tiled'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask tiled' }
        }
        'unity-hub'      = @{
            'Windows' = @{
                'scoop'  = 'scoop install unity-hub'
                'winget' = 'winget install Unity.UnityHub'
            }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://public-cdn.cloud.unity3d.com/hub/prod/UnityHub.AppImage -o UnityHub.AppImage' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask unity-hub' }
        }
        'dolphin'        = @{
            'Windows' = @{ 'scoop' = 'scoop install dolphin' }
            'Linux'   = @{ 'flatpak' = 'flatpak install flathub org.DolphinEmu.dolphin-emu' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask dolphin' }
        }
        'ryujinx'        = @{
            'Windows' = @{ 'scoop' = 'scoop install ryujinx' }
            'Linux'   = @{ 'flatpak' = 'flatpak install flathub org.ryujinx.Ryujinx' }
            'macOS'   = @{ 'scoop' = 'scoop install ryujinx' }
        }
        'retroarch'      = @{
            'Windows' = @{ 'scoop' = 'scoop install retroarch' }
            'Linux'   = @{
                'apt' = 'sudo apt install retroarch'; 'flatpak' = 'flatpak install flathub org.libretro.RetroArch'
                'pacman' = 'sudo pacman -S retroarch'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask retroarch' }
        }
        'blender'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install blender'
                'winget' = 'winget install BlenderFoundation.Blender'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install blender'; 'snap' = 'sudo snap install blender'
                'pacman' = 'sudo pacman -S blender'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask blender' }
        }
        'freecad'        = @{
            'Windows' = @{ 'scoop' = 'scoop install freecad' }
            'Linux'   = @{
                'apt' = 'sudo apt install freecad'; 'snap' = 'sudo snap install freecad'
                'pacman' = 'sudo pacman -S freecad'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask freecad' }
        }
        'openscad'       = @{
            'Windows' = @{ 'scoop' = 'scoop install openscad' }
            'Linux'   = @{
                'apt' = 'sudo apt install openscad'; 'pacman' = 'sudo pacman -S openscad'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask openscad' }
        }
        'adb'            = @{
            'Windows' = @{ 'scoop' = 'scoop install adb' }
            'Linux'   = @{
                'apt' = 'sudo apt install android-tools-adb'; 'dnf' = 'sudo dnf install android-tools'
                'pacman' = 'sudo pacman -S android-tools'
            }
            'macOS'   = @{ 'homebrew' = 'brew install --cask android-platform-tools' }
        }
        'scrcpy'         = @{
            'Windows' = @{ 'scoop' = 'scoop install scrcpy' }
            'Linux'   = @{
                'apt' = 'sudo apt install scrcpy'; 'dnf' = 'sudo dnf install scrcpy'
                'pacman' = 'sudo pacman -S scrcpy'
            }
            'macOS'   = @{ 'homebrew' = 'brew install scrcpy' }
        }
        'libimobiledevice' = @{
            'Windows' = @{ 'scoop' = 'scoop install libimobiledevice' }
            'Linux'   = @{
                'apt' = 'sudo apt install libimobiledevice-utils'; 'dnf' = 'sudo dnf install libimobiledevice'
                'pacman' = 'sudo pacman -S libimobiledevice'
            }
            'macOS'   = @{ 'homebrew' = 'brew install libimobiledevice' }
        }
        'pixelflasher'   = @{
            'Windows' = @{ 'scoop' = 'scoop install pixelflasher' }
            'Linux'   = @{ 'scoop' = 'scoop install pixelflasher' }
            'macOS'   = @{ 'scoop' = 'scoop install pixelflasher' }
        }
        'android-studio' = @{
            'Windows' = @{
                'scoop'  = 'scoop install android-studio'
                'winget' = 'winget install Google.AndroidStudio'
            }
            'Linux'   = @{ 'snap' = 'sudo snap install android-studio --classic' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask android-studio' }
        }
        'gitleaks'       = @{
            'Windows' = @{ 'scoop' = 'scoop install gitleaks' }
            'Linux'   = @{
                'apt' = 'sudo apt install gitleaks'; 'go' = 'go install github.com/gitleaks/gitleaks/v8@latest'
            }
            'macOS'   = @{ 'homebrew' = 'brew install gitleaks' }
        }
        'trufflehog'     = @{
            'Windows' = @{ 'scoop' = 'scoop install trufflehog' }
            'Linux'   = @{ 'go' = 'go install github.com/trufflesecurity/trufflehog/v3@latest' }
            'macOS'   = @{ 'homebrew' = 'brew install trufflehog' }
        }
        'osv-scanner'    = @{
            'Windows' = @{ 'scoop' = 'scoop install osv-scanner' }
            'Linux'   = @{ 'go' = 'go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest' }
            'macOS'   = @{ 'homebrew' = 'brew install osv-scanner' }
        }
        'yara'           = @{
            'Windows' = @{ 'scoop' = 'scoop install yara' }
            'Linux'   = @{
                'apt' = 'sudo apt install yara'; 'dnf' = 'sudo dnf install yara'
                'pacman' = 'sudo pacman -S yara'
            }
            'macOS'   = @{ 'homebrew' = 'brew install yara' }
        }
        'clamav'         = @{
            'Windows' = @{ 'scoop' = 'scoop install clamav' }
            'Linux'   = @{
                'apt' = 'sudo apt install clamav'; 'dnf' = 'sudo dnf install clamav'
                'pacman' = 'sudo pacman -S clamav'
            }
            'macOS'   = @{ 'homebrew' = 'brew install clamav' }
        }
        'dangerzone'     = @{
            'Windows' = @{ 'scoop' = 'scoop install dangerzone' }
            'Linux'   = @{ 'pip' = 'pip install dangerzone' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask dangerzone' }
        }
        'koboldcpp'      = @{
            'Windows' = @{ 'scoop' = 'scoop install koboldcpp' }
            'Linux'   = @{ 'git' = 'git clone https://github.com/LostRuins/koboldcpp.git && cd koboldcpp && make' }
            'macOS'   = @{ 'scoop' = 'scoop install koboldcpp' }
        }
        'llamafile'      = @{
            'Windows' = @{ 'scoop' = 'scoop install llamafile' }
            'Linux'   = @{ 'curl' = 'curl -LO https://github.com/Mozilla-Ocho/llamafile/releases/latest/download/llamafile' }
            'macOS'   = @{ 'homebrew' = 'brew install llamafile' }
        }
        'llama-cpp'      = @{
            'Windows' = @{ 'scoop' = 'scoop install llama.cpp' }
            'Linux'   = @{
                'apt' = 'sudo apt install llama.cpp'; 'brew' = 'brew install llama.cpp'
            }
            'macOS'   = @{ 'homebrew' = 'brew install llama.cpp' }
        }
        'bat'            = @{
            'Windows' = @{ 'scoop' = 'scoop install bat' }
            'Linux'   = @{
                'apt' = 'sudo apt install bat'; 'dnf' = 'sudo dnf install bat'
                'pacman' = 'sudo pacman -S bat'
            }
            'macOS'   = @{ 'homebrew' = 'brew install bat' }
        }
        'fd'             = @{
            'Windows' = @{ 'scoop' = 'scoop install fd' }
            'Linux'   = @{
                'apt' = 'sudo apt install fd-find'; 'dnf' = 'sudo dnf install fd-find'
                'pacman' = 'sudo pacman -S fd'
            }
            'macOS'   = @{ 'homebrew' = 'brew install fd' }
        }
        'zoxide'         = @{
            'Windows' = @{ 'scoop' = 'scoop install zoxide' }
            'Linux'   = @{
                'apt' = 'sudo apt install zoxide'; 'dnf' = 'sudo dnf install zoxide'
                'pacman' = 'sudo pacman -S zoxide'
            }
            'macOS'   = @{ 'homebrew' = 'brew install zoxide' }
        }
        'delta'          = @{
            'Windows' = @{ 'scoop' = 'scoop install delta' }
            'Linux'   = @{
                'apt' = 'sudo apt install git-delta'; 'dnf' = 'sudo dnf install git-delta'
                'pacman' = 'sudo pacman -S git-delta'
            }
            'macOS'   = @{ 'homebrew' = 'brew install git-delta' }
        }
        'tldr'           = @{
            'Windows' = @{ 'scoop' = 'scoop install tldr' }
            'Linux'   = @{
                'apt' = 'sudo apt install tldr'; 'npm' = 'npm install -g tldr'
                'pacman' = 'sudo pacman -S tldr'
            }
            'macOS'   = @{ 'homebrew' = 'brew install tldr' }
        }
        'git-cliff'      = @{
            'Windows' = @{ 'scoop' = 'scoop install git-cliff' }
            'Linux'   = @{
                'cargo' = 'cargo install git-cliff'; 'apt' = 'sudo apt install git-cliff'
                'pacman' = 'sudo pacman -S git-cliff'
            }
            'macOS'   = @{ 'homebrew' = 'brew install git-cliff' }
        }
        'git-tower'      = @{
            'Windows' = @{ 'scoop' = 'scoop install git-tower' }
            'Linux'   = @{ 'scoop' = 'scoop install git-tower' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask git-tower' }
        }
        'gitkraken'      = @{
            'Windows' = @{
                'scoop'  = 'scoop install gitkraken'
                'winget' = 'winget install Axosoft.GitKraken'
            }
            'Linux'   = @{ 'snap' = 'sudo snap install gitkraken' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask gitkraken' }
        }
        'gitbutler'      = @{
            'Windows' = @{ 'scoop' = 'scoop install gitbutler' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://releases.gitbutler.com/install.sh | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask gitbutler' }
        }
        'jj'             = @{
            'Windows' = @{ 'scoop' = 'scoop install jj' }
            'Linux'   = @{
                'cargo' = 'cargo install --locked jj-cli'; 'apt' = 'sudo apt install jj'
                'pacman' = 'sudo pacman -S jj'
            }
            'macOS'   = @{ 'homebrew' = 'brew install jj' }
        }
        'podman-desktop' = @{
            'Windows' = @{
                'scoop'  = 'scoop install podman-desktop'
                'winget' = 'winget install RedHat.Podman-Desktop'
            }
            'Linux'   = @{ 'flatpak' = 'flatpak install flathub io.podman_desktop.PodmanDesktop' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask podman-desktop' }
        }
        'rancher-desktop' = @{
            'Windows' = @{
                'scoop'  = 'scoop install rancher-desktop'
                'winget' = 'winget install suse.RancherDesktop'
            }
            'Linux'   = @{ 'flatpak' = 'flatpak install flathub io.rancherdesktop.app' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask rancher-desktop' }
        }
        'kompose'        = @{
            'Windows' = @{ 'scoop' = 'scoop install kompose' }
            'Linux'   = @{
                'apt' = 'sudo apt install kompose'; 'go' = 'go install github.com/kubernetes/kompose@latest'
                'pacman' = 'sudo pacman -S kompose'
            }
            'macOS'   = @{ 'homebrew' = 'brew install kompose' }
        }
        'balena-cli'     = @{
            'Windows' = @{ 'scoop' = 'scoop install balena-cli' }
            'Linux'   = @{ 'npm' = 'npm install -g balena-cli' }
            'macOS'   = @{ 'npm' = 'npm install -g balena-cli' }
        }
        'sql-workbench'  = @{
            'Windows' = @{ 'scoop' = 'scoop install sql-workbench' }
            'Linux'   = @{ 'scoop' = 'scoop install sql-workbench' }
            'macOS'   = @{ 'scoop' = 'scoop install sql-workbench' }
        }
        'conan'          = @{
            'Windows' = @{
                'scoop' = 'scoop install conan'
                'pip'   = 'pip install conan'
            }
            'Linux'   = @{
                'pip' = 'pip install conan'; 'apt' = 'sudo apt install conan'
            }
            'macOS'   = @{
                'pip'      = 'pip install conan'
                'homebrew' = 'brew install conan'
            }
        }
        'vcpkg'          = @{
            'Windows' = @{
                'git' = 'git clone https://github.com/microsoft/vcpkg && cd vcpkg && .\bootstrap-vcpkg.bat'
            }
            'Linux'   = @{
                'git' = 'git clone https://github.com/microsoft/vcpkg && cd vcpkg && ./bootstrap-vcpkg.sh'
            }
            'macOS'   = @{ 'homebrew' = 'brew install vcpkg' }
        }
        'mojo'           = @{
            'Windows' = @{ 'curl' = 'curl -fsSL https://get.modular.com | bash -s -- --yes' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://get.modular.com | bash -s -- --yes' }
            'macOS'   = @{ 'curl' = 'curl -fsSL https://get.modular.com | bash -s -- --yes' }
        }
        'cocoapods'      = @{
            'Windows' = @{ 'gem' = 'gem install cocoapods' }
            'Linux'   = @{
                'gem' = 'gem install cocoapods'; 'apt' = 'sudo apt install cocoapods'
            }
            'macOS'   = @{ 'gem' = 'gem install cocoapods'; 'homebrew' = 'brew install cocoapods' }
        }
        'cargo-audit'    = @{
            'Windows' = @{ 'cargo' = 'cargo install cargo-audit' }
            'Linux'   = @{
                'cargo' = 'cargo install cargo-audit'; 'apt' = 'sudo apt install cargo-audit'
                'pacman' = 'sudo pacman -S cargo-audit'
            }
            'macOS'   = @{ 'homebrew' = 'brew install cargo-audit' }
        }
        'cargo-outdated' = @{
            'Windows' = @{ 'cargo' = 'cargo install cargo-outdated' }
            'Linux'   = @{ 'cargo' = 'cargo install cargo-outdated' }
            'macOS'   = @{ 'cargo' = 'cargo install cargo-outdated' }
        }
        'nodejs'         = @{
            'Windows' = @{
                'scoop'  = 'scoop install nodejs'
                'winget' = 'winget install OpenJS.NodeJS'
            }
            'Linux'   = @{
                'apt' = 'sudo apt install nodejs npm'; 'dnf' = 'sudo dnf install nodejs'
                'pacman' = 'sudo pacman -S nodejs npm'
            }
            'macOS'   = @{ 'homebrew' = 'brew install node' }
        }
        'npm'            = @{
            'Windows' = @{ 'nodejs' = 'scoop install nodejs' }
            'Linux'   = @{ 'apt' = 'sudo apt install npm'; 'nodejs' = 'sudo apt install nodejs npm' }
            'macOS'   = @{ 'homebrew' = 'brew install node' }
        }
        'yarn'           = @{
            'Windows' = @{
                'scoop' = 'scoop install yarn'
                'npm'   = 'npm install -g yarn'
            }
            'Linux'   = @{ 'npm' = 'npm install -g yarn' }
            'macOS'   = @{ 'homebrew' = 'brew install yarn' }
        }
        'bun'            = @{
            'Windows' = @{ 'scoop' = 'scoop install bun' }
            'Linux'   = @{ 'curl' = 'curl -fsSL https://bun.sh/install | bash' }
            'macOS'   = @{ 'homebrew' = 'brew install bun' }
        }
        'hatch'          = @{
            'Windows' = @{
                'scoop' = 'scoop install hatch'
                'pip'   = 'pip install hatch'
            }
            'Linux'   = @{ 'pip' = 'pip install hatch'; 'uv' = 'uv tool install hatch' }
            'macOS'   = @{ 'homebrew' = 'brew install hatch'; 'pip' = 'pip install hatch' }
        }
        'pdm'            = @{
            'Windows' = @{
                'scoop' = 'scoop install pdm'
                'pip'   = 'pip install pdm'
            }
            'Linux'   = @{ 'pip' = 'pip install pdm'; 'uv' = 'uv tool install pdm' }
            'macOS'   = @{ 'homebrew' = 'brew install pdm'; 'pip' = 'pip install pdm' }
        }
        'pipenv'         = @{
            'Windows' = @{
                'scoop' = 'scoop install pipenv'
                'pip'   = 'pip install pipenv'
            }
            'Linux'   = @{ 'pip' = 'pip install pipenv' }
            'macOS'   = @{ 'homebrew' = 'brew install pipenv'; 'pip' = 'pip install pipenv' }
        }
        'newman'         = @{
            'Windows' = @{ 'npm' = 'npm install -g newman' }
            'Linux'   = @{ 'npm' = 'npm install -g newman' }
            'macOS'   = @{ 'npm' = 'npm install -g newman' }
        }
        'lmstudio'       = @{
            'Windows' = @{
                'scoop' = 'scoop install lmstudio'
                'curl'  = 'Install from https://lmstudio.ai/ and run lms bootstrap'
            }
            'Linux'   = @{ 'curl' = 'Install from https://lmstudio.ai/ and run lms bootstrap' }
            'macOS'   = @{ 'homebrew' = 'brew install --cask lmstudio' }
        }
        'starship'       = @{
            'Windows' = @{
                'scoop'  = 'scoop install starship'
                'winget' = 'winget install Starship.Starship'
                'cargo'  = 'cargo install starship --locked'
            }
            'Linux'   = @{
                'curl'   = 'curl -sS https://starship.rs/install.sh | sh'
                'cargo'  = 'cargo install starship --locked'
                'apt'    = 'sudo apt install starship'
                'pacman' = 'sudo pacman -S starship'
            }
            'macOS'   = @{
                'homebrew' = 'brew install starship'
                'curl'     = 'curl -sS https://starship.rs/install.sh | sh'
            }
        }
        'oh-my-posh'     = @{
            'Windows' = @{
                'scoop'  = 'scoop install oh-my-posh'
                'winget' = 'winget install JanDeDobbeleer.OhMyPosh'
            }
            'Linux'   = @{
                'curl'  = 'curl -s https://ohmyposh.dev/install.sh | bash -s'
                'scoop' = 'scoop install oh-my-posh'
            }
            'macOS'   = @{
                'homebrew' = 'brew install oh-my-posh'
                'curl'     = 'curl -s https://ohmyposh.dev/install.sh | bash -s'
            }
        }
        'mage'           = @{
            'Windows' = @{
                'scoop' = 'scoop install mage'
                'go'    = 'go install github.com/magefile/mage@latest'
            }
            'Linux'   = @{
                'go'     = 'go install github.com/magefile/mage@latest'
                'pacman' = 'sudo pacman -S mage'
            }
            'macOS'   = @{
                'homebrew' = 'brew install mage'
                'go'       = 'go install github.com/magefile/mage@latest'
            }
        }
        'cargo-watch'    = @{
            'Windows' = @{
                'scoop' = 'scoop install cargo-watch'
                'cargo' = 'cargo install cargo-watch'
            }
            'Linux'   = @{
                'cargo'  = 'cargo install cargo-watch'
                'pacman' = 'sudo pacman -S cargo-watch'
            }
            'macOS'   = @{
                'homebrew' = 'brew install cargo-watch'
                'cargo'    = 'cargo install cargo-watch'
            }
        }
        'vite'           = @{
            'Windows' = @{
                'npm'   = 'npm install -g vite'
                'scoop' = 'scoop install vite'
            }
            'Linux'   = @{ 'npm' = 'npm install -g vite' }
            'macOS'   = @{
                'npm'      = 'npm install -g vite'
                'homebrew' = 'brew install vite'
            }
        }
        'comfy-cli'      = @{
            'Windows' = @{
                'scoop' = 'scoop install comfy-cli'
                'uv'    = 'uv tool install comfy-cli'
                'pip'   = 'pip install comfy-cli'
            }
            'Linux'   = @{
                'uv'  = 'uv tool install comfy-cli'
                'pip' = 'pip install comfy-cli'
            }
            'macOS'   = @{
                'homebrew' = 'brew install comfy-cli'
                'uv'       = 'uv tool install comfy-cli'
            }
        }
        '@angular/cli'   = @{
            'Windows' = @{
                'npm'   = 'npm install -g @angular/cli'
                'scoop' = 'scoop install ng'
            }
            'Linux'   = @{ 'npm' = 'npm install -g @angular/cli' }
            'macOS'   = @{ 'npm' = 'npm install -g @angular/cli' }
        }
        'scoop'          = @{
            'Windows' = @{
                'powershell' = 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex'
            }
            'Linux'   = @{ 'powershell' = 'irm get.scoop.sh | iex' }
            'macOS'   = @{ 'powershell' = 'irm get.scoop.sh | iex' }
        }
        'winget'         = @{
            'Windows' = @{
                'curl' = 'Install App Installer from https://aka.ms/getwinget (winget ships with Windows 10/11)'
            }
        }
        'homebrew'       = @{
            'Linux'   = @{
                'curl' = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            }
            'macOS'   = @{
                'curl' = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            }
            'Windows' = @{
                'curl' = 'Install from https://brew.sh/ (native Windows or WSL)'
            }
        }
        'chocolatey'     = @{
            'Windows' = @{
                'powershell' = 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(''https://community.chocolatey.org/install.ps1''))'
            }
        }
        'jest'           = @{
            'Windows' = @{
                'npm'   = 'npm install -g jest'
                'scoop' = 'scoop install jest'
            }
            'Linux'   = @{ 'npm' = 'npm install -g jest' }
            'macOS'   = @{
                'npm'      = 'npm install -g jest'
                'homebrew' = 'brew install jest'
            }
        }
        'vitest'         = @{
            'Windows' = @{ 'npm' = 'npm install -g vitest' }
            'Linux'   = @{ 'npm' = 'npm install -g vitest' }
            'macOS'   = @{ 'npm' = 'npm install -g vitest' }
        }
        'playwright'     = @{
            'Windows' = @{
                'npm'   = 'npm install -g playwright'
                'scoop' = 'scoop install playwright'
            }
            'Linux'   = @{ 'npm' = 'npm install -g playwright' }
            'macOS'   = @{ 'npm' = 'npm install -g playwright' }
        }
        'cypress'        = @{
            'Windows' = @{
                'npm'   = 'npm install -g cypress'
                'scoop' = 'scoop install cypress'
            }
            'Linux'   = @{ 'npm' = 'npm install -g cypress' }
            'macOS'   = @{ 'npm' = 'npm install -g cypress' }
        }
        'mocha'          = @{
            'Windows' = @{ 'npm' = 'npm install -g mocha' }
            'Linux'   = @{ 'npm' = 'npm install -g mocha' }
            'macOS'   = @{ 'npm' = 'npm install -g mocha' }
        }
        'typescript'     = @{
            'Windows' = @{
                'npm'   = 'npm install -g typescript'
                'scoop' = 'scoop install typescript'
            }
            'Linux'   = @{ 'npm' = 'npm install -g typescript' }
            'macOS'   = @{
                'npm'      = 'npm install -g typescript'
                'homebrew' = 'brew install typescript'
            }
        }
        'create-vite'    = @{
            'Windows' = @{ 'npm' = 'npm create vite@latest' }
            'Linux'   = @{ 'npm' = 'npm create vite@latest' }
            'macOS'   = @{ 'npm' = 'npm create vite@latest' }
        }
        'openssh'        = @{
            'Windows' = @{
                'scoop'  = 'scoop install openssh'
                'winget' = 'winget install Microsoft.OpenSSH.Beta'
            }
            'Linux'   = @{
                'apt'    = 'sudo apt install openssh-client'
                'dnf'    = 'sudo dnf install openssh-clients'
                'pacman' = 'sudo pacman -S openssh'
            }
            'macOS'   = @{ 'homebrew' = 'brew install openssh' }
        }
        'djvulibre'      = @{
            'Windows' = @{ 'scoop' = 'scoop install djvulibre' }
            'Linux'   = @{
                'apt'    = 'sudo apt install djvulibre-bin'
                'dnf'    = 'sudo dnf install djvulibre'
                'pacman' = 'sudo pacman -S djvulibre'
            }
            'macOS'   = @{ 'homebrew' = 'brew install djvulibre' }
        }
    }
}

<#
.SYNOPSIS
    Gets tool-specific installation method.
.DESCRIPTION
    Retrieves the best installation method for a specific tool based on preferences,
    platform, and availability.
.PARAMETER ToolName
    Name of the tool to get installation method for.
.PARAMETER Platform
    Target platform (Windows, Linux, macOS). If not specified, auto-detects.
.PARAMETER PreferredMethod
    Preferred installation method (scoop, npm, pip, etc.). If not specified, uses preferences.
.OUTPUTS
    System.String
.EXAMPLE
    Get-ToolSpecificInstallMethod -ToolName 'docker'
#>
function global:Get-ToolSpecificInstallMethod {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [string]$Platform,
        
        [string]$PreferredMethod
    )
    
    $registry = Get-ToolInstallMethodRegistry
    $packageName = if (Get-Command Resolve-InstallPackageName -ErrorAction SilentlyContinue) {
        Resolve-InstallPackageName -ToolName $ToolName
    }
    else {
        $ToolName
    }
    $toolLower = $packageName.ToLower()
    
    if (-not $registry.ContainsKey($toolLower)) {
        return $null
    }
    
    $toolMethods = $registry[$toolLower]
    
    # Detect platform if not provided
    if (-not $Platform) {
        $Platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
    }
    
    if (-not $toolMethods.ContainsKey($Platform)) {
        return $null
    }
    
    $platformMethods = $toolMethods[$Platform]
    
    # If preferred method specified, use it if available
    if ($PreferredMethod) {
        $prefLower = $PreferredMethod.ToLower()
        if ($platformMethods.ContainsKey($prefLower)) {
            $method = $platformMethods[$prefLower]
            # Check if the method is available
            if ($prefLower -eq 'scoop' -and (Test-CachedCommand 'scoop')) {
                return $method
            }
            elseif ($prefLower -eq 'npm' -and (Test-CachedCommand 'npm')) {
                return $method
            }
            elseif ($prefLower -eq 'pip' -and (Test-CachedCommand 'pip')) {
                return $method
            }
            elseif ($prefLower -eq 'winget' -and (Test-CachedCommand 'winget')) {
                return $method
            }
            elseif ($prefLower -eq 'homebrew' -and (Test-CachedCommand 'brew')) {
                return $method
            }
            elseif ($prefLower -eq 'cargo' -and (Test-CachedCommand 'cargo')) {
                return $method
            }
            elseif ($prefLower -eq 'curl') {
                return $method
            }
            elseif ($prefLower -eq 'powershell' -and ($Platform -eq 'Windows' -or $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
                return $method
            }
        }
    }
    
    # Try to use preferences
    $systemPm = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower() } else { 'auto' }
    
    # Try preferred system package manager first
    if ($systemPm -ne 'auto' -and $platformMethods.ContainsKey($systemPm)) {
        $method = $platformMethods[$systemPm]
        if (Test-CommandAvailable -CommandName $systemPm) {
            return $method
        }
    }
    
    # Try language-specific preferences
    if ($toolLower -in @('pnpm', 'npm', 'yarn', 'bun')) {
        $nodePm = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        if ($nodePm -ne 'auto' -and $platformMethods.ContainsKey($nodePm)) {
            $method = $platformMethods[$nodePm]
            if (Test-CommandAvailable -CommandName $nodePm) {
                return $method
            }
        }
    }
    elseif ($toolLower -in @('uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye')) {
        $pythonPm = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        if ($pythonPm -ne 'auto' -and $platformMethods.ContainsKey($pythonPm)) {
            $method = $platformMethods[$pythonPm]
            if (Test-CommandAvailable -CommandName $pythonPm) {
                return $method
            }
        }
    }
    
    # Auto-detect: try methods in order of preference
    $preferredOrder = @('powershell', 'scoop', 'homebrew', 'npm', 'pip', 'cargo', 'winget', 'curl', 'apt', 'yum', 'dnf')
    foreach ($methodName in $preferredOrder) {
        if ($platformMethods.ContainsKey($methodName)) {
            if ($methodName -eq 'curl' -or $methodName -eq 'powershell' -or (Test-CommandAvailable -CommandName $methodName)) {
                # For powershell, verify we're on Windows
                if ($methodName -eq 'powershell' -and $Platform -ne 'Windows' -and -not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
                    continue
                }
                return $platformMethods[$methodName]
            }
        }
    }
    
    # Return first available method
    foreach ($methodName in $platformMethods.Keys) {
        return $platformMethods[$methodName]
    }
    
    return $null
}

<#
.SYNOPSIS
    Helper function to test if a command is available.
.DESCRIPTION
    Checks if a command is available in the current environment.
.PARAMETER CommandName
    Name of the command to check.
.OUTPUTS
    System.Boolean
.EXAMPLE
    Test-CommandAvailable -CommandName 'Get-GitStatus'
#>
function global:Test-CommandAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )
    
    # Map common package manager names to their commands
    $commandMap = @{
        'scoop'      = 'scoop'
        'homebrew'   = 'brew'
        'chocolatey' = 'choco'
        'npm'        = 'npm'
        'pip'        = 'pip'
        'cargo'      = 'cargo'
        'winget'     = 'winget'
        'apt'        = 'apt'
        'yum'        = 'yum'
        'dnf'        = 'dnf'
        'pacman'     = 'pacman'
    }
    
    $actualCommand = if ($commandMap.ContainsKey($CommandName.ToLower())) {
        $commandMap[$CommandName.ToLower()]
    }
    else {
        $CommandName
    }

    if (Get-Command Test-CachedCommand -ErrorAction SilentlyContinue) {
        return [bool](Test-CachedCommand -Name $actualCommand -CacheTTLMinutes 1)
    }

    return [bool](Get-Command $actualCommand -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Generates a prioritized fallback chain for installation methods.
.DESCRIPTION
    Creates a formatted string with multiple installation options in priority order,
    showing the preferred method first, followed by available fallbacks.
.PARAMETER PreferredMethod
    The preferred installation command (if available).
.PARAMETER FallbackMethods
    Array of fallback installation commands in priority order.
.PARAMETER MaxFallbacks
    Maximum number of fallback options to show (default: 3).
.OUTPUTS
    System.String
.EXAMPLE
    Get-InstallMethodFallbackChain -PreferredMethod 'value' -FallbackMethods @()
#>
function global:Get-InstallMethodFallbackChain {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$PreferredMethod,
        
        [string[]]$FallbackMethods = @(),
        
        [int]$MaxFallbacks = 3
    )
    
    $methods = @()
    
    # Add preferred method if provided
    if ($PreferredMethod) {
        $methods += $PreferredMethod
    }
    
    # Add available fallbacks (up to MaxFallbacks)
    $fallbackCount = 0
    foreach ($fallback in $FallbackMethods) {
        if ($fallbackCount -ge $MaxFallbacks) {
            break
        }
        # Don't add duplicates
        if ($fallback -and $fallback -ne $PreferredMethod -and $fallback -notin $methods) {
            $methods += $fallback
            $fallbackCount++
        }
    }
    
    # Format the chain
    if ($methods.Count -eq 0) {
        return $null
    }
    elseif ($methods.Count -eq 1) {
        return $methods[0]
    }
    else {
        # Format: "primary (or: fallback1, or: fallback2, or: fallback3)"
        $primary = $methods[0]
        $fallbacks = $methods[1..($methods.Count - 1)]
        $fallbackStr = ($fallbacks | ForEach-Object { "or: $_" }) -join ', '
        return "$primary ($fallbackStr)"
    }
}

<#
.SYNOPSIS
    Gets prioritized fallback chain for system package managers.
.DESCRIPTION
    Returns installation commands for system package managers in priority order,
    checking availability and respecting preferences.
.PARAMETER ToolName
    Name of the tool to install.
.PARAMETER Platform
    Target platform (Windows, Linux, macOS). If not specified, auto-detects.
.PARAMETER PreferredManager
    Preferred package manager name (scoop, winget, etc.).
.OUTPUTS
    System.Collections.Hashtable
.EXAMPLE
    Get-SystemPackageManagerFallbackChain -ToolName 'docker'
#>
function global:Get-SystemPackageManagerFallbackChain {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,
        
        [string]$Platform,
        
        [string]$PreferredManager
    )
    
    # Detect platform if not provided
    if (-not $Platform) {
        $Platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
    }
    
    # Define platform-specific package managers in priority order
    $packageManagers = switch ($Platform) {
        'Windows' {
            @(
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
                @{ Name = 'winget'; Command = 'winget'; InstallCmd = "winget install $ToolName" }
                @{ Name = 'chocolatey'; Command = 'choco'; InstallCmd = "choco install $ToolName -y" }
            )
        }
        'Linux' {
            @(
                @{ Name = 'apt'; Command = 'apt'; InstallCmd = "sudo apt install $ToolName" }
                @{ Name = 'dnf'; Command = 'dnf'; InstallCmd = "sudo dnf install $ToolName" }
                @{ Name = 'yum'; Command = 'yum'; InstallCmd = "sudo yum install $ToolName" }
                @{ Name = 'pacman'; Command = 'pacman'; InstallCmd = "sudo pacman -S $ToolName" }
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
        'macOS' {
            @(
                @{ Name = 'homebrew'; Command = 'brew'; InstallCmd = "brew install $ToolName" }
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
        default {
            @(
                @{ Name = 'scoop'; Command = 'scoop'; InstallCmd = "scoop install $ToolName" }
            )
        }
    }
    
    # Check availability and build priority list
    $availableMethods = @()
    $preferredMethod = $null
    $preferredIndex = -1
    
    for ($i = 0; $i -lt $packageManagers.Count; $i++) {
        $pm = $packageManagers[$i]
        $isAvailable = Test-CommandAvailable -CommandName $pm.Command
        
        if ($isAvailable) {
            $availableMethods += $pm.InstallCmd
            
            # Check if this is the preferred manager
            if ($PreferredManager -and $pm.Name.ToLower() -eq $PreferredManager.ToLower()) {
                $preferredMethod = $pm.InstallCmd
                $preferredIndex = $availableMethods.Count - 1
            }
        }
    }
    
    # Reorder if preferred method is found
    if ($preferredIndex -gt 0) {
        $preferred = $availableMethods[$preferredIndex]
        $availableMethods = @($preferred) + ($availableMethods | Where-Object { $_ -ne $preferred })
    }
    
    # Generate fallback chain
    $fallbackChain = Get-InstallMethodFallbackChain -PreferredMethod $preferredMethod -FallbackMethods $availableMethods -MaxFallbacks 3
    
    return @{
        Preferred     = $preferredMethod
        Available     = $availableMethods
        FallbackChain = $fallbackChain
        Platform      = $Platform
    }
}

<#
.SYNOPSIS
    Validates preference-aware install preferences.
.DESCRIPTION
    Checks if the current preferences are valid and the specified tools are available.
.PARAMETER PreferenceType
    Type of preference to validate (python-package, node-package, system-package, etc.).
    If not specified, validates all preferences.
.OUTPUTS
    System.Collections.Hashtable
.EXAMPLE
    Test-PreferenceAwareInstallPreferences -PreferenceType 'value'
#>
function global:Test-PreferenceAwareInstallPreferences {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'system-package', 'all')]
        [string]$PreferenceType = 'all'
    )
    
    $results = @{
        Valid       = $true
        Errors      = @()
        Warnings    = @()
        Preferences = @{}
    }
    
    # Validate Python package manager preference
    if ($PreferenceType -in @('python-package', 'all')) {
        $pythonPm = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_PYTHON_PACKAGE_MANAGER'] = $pythonPm
        
        if ($pythonPm -ne 'auto') {
            $validPythonPms = @('pip', 'uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye', 'conda')
            if ($pythonPm -notin $validPythonPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_PYTHON_PACKAGE_MANAGER: $pythonPm. Valid values: $($validPythonPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $pythonPm)) {
                $results.Warnings += "PS_PYTHON_PACKAGE_MANAGER is set to '$pythonPm' but the command is not available"
            }
        }
    }
    
    # Validate Node package manager preference
    if ($PreferenceType -in @('node-package', 'all')) {
        $nodePm = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_NODE_PACKAGE_MANAGER'] = $nodePm
        
        if ($nodePm -ne 'auto') {
            $validNodePms = @('npm', 'pnpm', 'yarn', 'bun')
            if ($nodePm -notin $validNodePms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_NODE_PACKAGE_MANAGER: $nodePm. Valid values: $($validNodePms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $nodePm)) {
                $results.Warnings += "PS_NODE_PACKAGE_MANAGER is set to '$nodePm' but the command is not available"
            }
        }
    }
    
    # Validate Python runtime preference
    if ($PreferenceType -in @('python-runtime', 'all')) {
        $pythonRuntime = if ($env:PS_PYTHON_RUNTIME) { $env:PS_PYTHON_RUNTIME.ToLower() } else { 'auto' }
        $results.Preferences['PS_PYTHON_RUNTIME'] = $pythonRuntime
        
        if ($pythonRuntime -ne 'auto') {
            $validRuntimes = @('python', 'python3', 'py')
            if ($pythonRuntime -notin $validRuntimes) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_PYTHON_RUNTIME: $pythonRuntime. Valid values: $($validRuntimes -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $pythonRuntime)) {
                $results.Warnings += "PS_PYTHON_RUNTIME is set to '$pythonRuntime' but the command is not available"
            }
        }
    }
    
    # Validate Rust package manager preference
    if ($PreferenceType -in @('rust-package', 'all')) {
        $rustPm = if ($env:PS_RUST_PACKAGE_MANAGER) { $env:PS_RUST_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_RUST_PACKAGE_MANAGER'] = $rustPm
        
        if ($rustPm -ne 'auto') {
            $validRustPms = @('cargo', 'cargo-binstall')
            if ($rustPm -notin $validRustPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_RUST_PACKAGE_MANAGER: $rustPm. Valid values: $($validRustPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $rustPm)) {
                $results.Warnings += "PS_RUST_PACKAGE_MANAGER is set to '$rustPm' but the command is not available"
            }
        }
    }
    
    # Validate system package manager preference
    if ($PreferenceType -in @('system-package', 'all')) {
        $systemPm = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER.ToLower() } else { 'auto' }
        $results.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] = $systemPm
        
        if ($systemPm -ne 'auto') {
            $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
                try { (Get-Platform).Name } catch { 'Windows' }
            }
            else {
                if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                elseif ($IsLinux) { 'Linux' }
                elseif ($IsMacOS) { 'macOS' }
                else { 'Windows' }
            }
            
            $validSystemPms = switch ($platform) {
                'Windows' { @('scoop', 'winget', 'chocolatey', 'auto') }
                'Linux' { @('apt', 'yum', 'dnf', 'pacman', 'scoop', 'auto') }
                'macOS' { @('homebrew', 'scoop', 'auto') }
                default { @('scoop', 'auto') }
            }
            
            if ($systemPm -notin $validSystemPms) {
                $results.Valid = $false
                $results.Errors += "Invalid PS_SYSTEM_PACKAGE_MANAGER for $platform : $systemPm. Valid values: $($validSystemPms -join ', ')"
            }
            elseif (-not (Test-CommandAvailable -CommandName $systemPm)) {
                $results.Warnings += "PS_SYSTEM_PACKAGE_MANAGER is set to '$systemPm' but the command is not available"
            }
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Interactive preference setup for install hints.
.DESCRIPTION
    Guides the user through setting up their preferences for package managers and runtimes.
.PARAMETER PreferenceType
    Type of preference to set up (python-package, node-package, system-package, etc.).
    If not specified, sets up all preferences.
.PARAMETER NonInteractive
    If specified, skips interactive prompts and uses defaults.
.OUTPUTS
    System.Collections.Hashtable
.EXAMPLE
    Set-PreferenceAwareInstallPreferences -Name 'name' -Value 'value'
#>
function global:Set-PreferenceAwareInstallPreferences {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateSet('python-package', 'node-package', 'python-runtime', 'rust-package', 'go-package', 'java-build-tool', 'ruby-package', 'php-package', 'dotnet-package', 'dart-package', 'elixir-package', 'system-package', 'all')]
        [string]$PreferenceType = 'all',
        
        [switch]$NonInteractive
    )
    
    $results = @{
        Preferences = @{}
        Updated     = @()
    }
    
    # Python package manager
    if ($PreferenceType -in @('python-package', 'all')) {
        $current = if ($env:PS_PYTHON_PACKAGE_MANAGER) { $env:PS_PYTHON_PACKAGE_MANAGER } else { 'auto' }
        $options = @('auto', 'pip', 'uv', 'poetry', 'pipenv', 'hatch', 'pdm', 'rye', 'conda')
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nPython Package Manager Preference" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_PYTHON_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_PYTHON_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_PYTHON_PACKAGE_MANAGER'
        }
    }
    
    # Node package manager
    if ($PreferenceType -in @('node-package', 'all')) {
        $current = if ($env:PS_NODE_PACKAGE_MANAGER) { $env:PS_NODE_PACKAGE_MANAGER } else { 'auto' }
        $options = @('auto', 'npm', 'pnpm', 'yarn', 'bun')
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nNode Package Manager Preference" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_NODE_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_NODE_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_NODE_PACKAGE_MANAGER'
        }
    }
    
    # System package manager
    if ($PreferenceType -in @('system-package', 'all')) {
        $current = if ($env:PS_SYSTEM_PACKAGE_MANAGER) { $env:PS_SYSTEM_PACKAGE_MANAGER } else { 'auto' }
        $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
            try { (Get-Platform).Name } catch { 'Windows' }
        }
        else {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
            elseif ($IsLinux) { 'Linux' }
            elseif ($IsMacOS) { 'macOS' }
            else { 'Windows' }
        }
        
        $options = switch ($platform) {
            'Windows' { @('auto', 'scoop', 'winget', 'chocolatey') }
            'Linux' { @('auto', 'apt', 'yum', 'dnf', 'pacman', 'scoop') }
            'macOS' { @('auto', 'homebrew', 'scoop') }
            default { @('auto', 'scoop') }
        }
        $available = $options | Where-Object { $_ -eq 'auto' -or (Test-CommandAvailable -CommandName $_) }
        
        if (-not $NonInteractive) {
            Write-Host "`nSystem Package Manager Preference ($platform)" -ForegroundColor Cyan
            Write-Host "Current: $current" -ForegroundColor Gray
            Write-Host "Available options:" -ForegroundColor Gray
            for ($i = 0; $i -lt $options.Count; $i++) {
                $marker = if ($options[$i] -in $available) { '✓' } else { '✗' }
                $default = if ($options[$i] -eq $current) { ' (current)' } else { '' }
                Write-Host "  $($i + 1). $marker $($options[$i])$default" -ForegroundColor $(if ($options[$i] -in $available) { 'Green' } else { 'Yellow' })
            }
            
            $choice = Read-Host "`nSelect preference (1-$($options.Count), or press Enter for '$current')"
            if ([string]::IsNullOrWhiteSpace($choice)) {
                $choice = $current
            }
            elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $options.Count) {
                $choice = $options[[int]$choice - 1]
            }
        }
        else {
            $choice = $current
        }
        
        if ($choice -ne $current) {
            $env:PS_SYSTEM_PACKAGE_MANAGER = $choice
            $results.Preferences['PS_SYSTEM_PACKAGE_MANAGER'] = $choice
            $results.Updated += 'PS_SYSTEM_PACKAGE_MANAGER'
        }
    }
    
    # Validate preferences after setting
    $validation = Test-PreferenceAwareInstallPreferences -PreferenceType $PreferenceType
    if (-not $validation.Valid) {
        Write-Warning "Some preferences are invalid: $($validation.Errors -join '; ')"
    }
    if ($validation.Warnings.Count -gt 0) {
        foreach ($warning in $validation.Warnings) {
            Write-Warning $warning
        }
    }
    
    if (-not $NonInteractive -and $results.Updated.Count -gt 0) {
        Write-Host "`nPreferences updated. Add these to your .env file to persist:" -ForegroundColor Green
        foreach ($key in $results.Updated) {
            Write-Host "  $key=$($results.Preferences[$key])" -ForegroundColor Yellow
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Displays all collected missing tool warnings in a formatted table.
.DESCRIPTION
    Shows a table of all missing tools that were detected during profile loading,
    including their installation hints. This provides a consolidated view instead
    of sporadic warnings during fragment loading.
.OUTPUTS
    None
#>
function global:Show-MissingToolWarningsTable {
    [CmdletBinding()]
    param()

    if (Test-EnvBool $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS) {
        return
    }

    if (-not $global:CollectedMissingToolWarnings -or $global:CollectedMissingToolWarnings.Count -eq 0) {
        return
    }

    # Sort warnings by tool name for consistent display
    $sortedWarnings = $global:CollectedMissingToolWarnings | Sort-Object -Property Tool

    Write-Host "`n[Missing Tools]" -ForegroundColor Yellow
    Write-Host ""

    # Create table data
    $tableData = $sortedWarnings | ForEach-Object {
        $tool = $_.Tool
        $installHint = if ($_.InstallHint) {
            # Clean up common prefixes like "Install with:", "Install from:", etc.
            $hint = $_.InstallHint.Trim()
            if ($hint -match '^(Install with:|Install from:)\s*(.+)$') {
                $matches[2].Trim()
            }
            else {
                $hint
            }
        }
        else {
            # Extract install hint from message if available
            $message = $_.Message
            if ($message -match 'not found\.\s*(.+)') {
                $matches[1].Trim()
            }
            else {
                'See tool documentation'
            }
        }

        [PSCustomObject]@{
            Tool        = $tool
            InstallHint = $installHint
        }
    }

    # Display table - use direct Write-Host to avoid Out-String hang
    # Format-Table | Out-String can hang in some scenarios, so we format manually
    if ($tableData.Count -gt 0) {
        # Calculate column widths
        $toolWidth = [Math]::Max(4, ($tableData | ForEach-Object { $_.Tool.Length } | Measure-Object -Maximum).Maximum)
        $hintWidth = [Math]::Max(11, ($tableData | ForEach-Object { $_.InstallHint.Length } | Measure-Object -Maximum).Maximum)
        
        # Write header
        Write-Host ("{0,-$toolWidth} {1}" -f 'Tool', 'InstallHint') -ForegroundColor Cyan
        Write-Host ("{0,-$toolWidth} {1}" -f ('-' * $toolWidth), ('-' * $hintWidth)) -ForegroundColor Cyan
        
        # Write rows
        foreach ($row in $tableData) {
            Write-Host ("{0,-$toolWidth} {1}" -f $row.Tool, $row.InstallHint)
        }
    }

    # Clear collected warnings after display
    $global:CollectedMissingToolWarnings.Clear()
}

