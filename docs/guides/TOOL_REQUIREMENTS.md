# Tool Requirements for Tests

This document lists all tools and packages required or recommended for running the PowerShell profile test suite.

## Overview

The test suite uses a tool detection framework (`TestSupport/ToolDetection.ps1`) to gracefully handle missing tools. Tests will skip with clear messages when optional tools are missing, and provide installation recommendations.

## Tool Detection Framework

The framework provides several functions:

- **`Test-ToolAvailable`** - Checks if a command/tool is available in PATH
- **`Get-ToolRecommendations`** - Gets recommendations for common development tools
- **`Get-MissingTools`** - Gets list of missing tools from recommendations
- **`Show-ToolRecommendations`** - Displays tool recommendations in a formatted table

### Usage in Tests

```powershell
# Check tool availability with installation recommendation
$tool = Test-ToolAvailable -ToolName 'docker' -InstallCommand 'scoop install docker' -Silent
if (-not $tool.Available) {
    Set-ItResult -Skipped -Because "docker not available. Install with: $($tool.InstallCommand)"
    return
}

# Use the tool
docker --version | Should -Not -BeNullOrEmpty
```

## Required Tools

These tools are **required** for the test suite to run:

- **PowerShell** (pwsh) - PowerShell 7+ for cross-platform testing
- **Pester** - Test framework (automatically installed via module dependencies)
- **Git** - Version control (for some integration tests)

## Optional Tools

These tools are **optional** but enable additional test coverage:

### Container Tools

- **docker** - Container runtime
  - Install: `scoop install docker`
  - URL: https://www.docker.com/get-started
- **podman** - Alternative container runtime
  - Install: `scoop install podman`
  - URL: https://podman.io/getting-started/installation

### Infrastructure & Cloud Tools

- **kubectl** - Kubernetes command-line tool
  - Install: `scoop install kubectl`
  - URL: https://kubernetes.io/docs/tasks/tools/
- **terraform** - Infrastructure as code
  - Install: `scoop install terraform`
  - URL: https://www.terraform.io/downloads
- **aws** - AWS CLI
  - Install: `scoop install aws`
  - URL: https://aws.amazon.com/cli/
- **az** - Azure CLI
  - Install: `scoop install azure-cli`
  - URL: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
- **gcloud** - Google Cloud SDK
  - Install: `scoop install gcloud`
  - URL: https://cloud.google.com/sdk/docs/install

### Terminal & Prompt Tools

- **oh-my-posh** - Prompt framework
  - Install: `scoop install oh-my-posh`
  - URL: https://ohmyposh.dev/docs/installation
- **starship** - Cross-shell prompt
  - Install: `scoop install starship`
  - URL: https://starship.rs/guide/#%F0%9F%9A%80-installation

### Modern CLI Tools

- **bat** - Cat clone with syntax highlighting
  - Install: `scoop install bat`
  - URL: https://github.com/sharkdp/bat
- **fd** - Find alternative
  - Install: `scoop install fd`
  - URL: https://github.com/sharkdp/fd
- **http** - HTTP client (httpie)
  - Install: `scoop install httpie`
  - URL: https://httpie.io/
- **zoxide** - Smarter cd command
  - Install: `scoop install zoxide`
  - URL: https://github.com/ajeetdsouza/zoxide
- **delta** - Git diff viewer
  - Install: `scoop install delta`
  - URL: https://github.com/dandavison/delta
- **tldr** - Simplified man pages
  - Install: `scoop install tldr`
  - URL: https://tldr.sh/
- **procs** - Modern ps alternative
  - Install: `scoop install procs`
  - URL: https://github.com/dalance/procs
- **dust** - Disk usage analyzer
  - Install: `scoop install dust`
  - URL: https://github.com/bootandy/dust

### Development Tools

- **ssh** - Secure shell client
  - Install: `scoop install openssh`
  - URL: https://www.openssh.com/
- **ansible** - Configuration management
  - Install: `pip install ansible`
  - URL: https://docs.ansible.com/ansible/latest/installation_guide/index.html
- **gh** - GitHub CLI
  - Install: `scoop install gh`
  - URL: https://cli.github.com/
- **wsl** - Windows Subsystem for Linux
  - Install: `wsl --install`
  - URL: https://docs.microsoft.com/en-us/windows/wsl/install

### Package Managers

- **pnpm** - Fast, disk space efficient package manager
  - Install: `npm install -g pnpm`
  - URL: https://pnpm.io/installation
- **uv** - Fast Python package installer
  - Install: `pip install uv`
  - URL: https://github.com/astral-sh/uv

## Package Requirements

### Python Packages

Python packages are checked using `Test-PythonPackageAvailable` from `TestSupport/TestPythonHelpers.ps1`. The function supports both system Python and UV-managed installations.

**Scientific Data Packages:**

- **ion-python** - Amazon Ion format support
- **pyodbc** - ODBC database connectivity
- **dbfread** - DBF file reading
- **dbf** - DBF file manipulation
- **pyreadstat** - SPSS/Stata/SAS file reading
- **pandas** - Data analysis library
- **scipy** - Scientific computing
- **astropy** - Astronomy and astrophysics
- **pyarrow** - Apache Arrow support
- **delta-spark** - Delta Lake support
- **deltalake** - Delta Lake Python bindings
- **pyiceberg** - Apache Iceberg support
- **python-snappy** - Snappy compression
- **h5py** - HDF5 file format
- **netCDF4** - NetCDF file format
- **numpy** - Numerical computing

**Installation:**

```powershell
# Using pip
pip install ion-python pyodbc dbfread dbf pyreadstat pandas scipy astropy pyarrow delta-spark deltalake pyiceberg python-snappy h5py netCDF4 numpy

# Using uv
uv pip install ion-python pyodbc dbfread dbf pyreadstat pandas scipy astropy pyarrow delta-spark deltalake pyiceberg python-snappy h5py netCDF4 numpy
```

### Scoop Packages

Scoop packages are checked using `Test-ScoopPackageAvailable` from `TestSupport/TestScoopHelpers.ps1`. The function requires Scoop to be installed.

**Categories:**

- **CLI Tools:** bat, fd, http, zoxide, delta, tldr, procs, dust
- **Containers:** docker, podman
- **Document Formats:** pandoc, libreoffice
- **File/Data Tools:** jq, yq, rg (ripgrep)
- **Git Tools:** gh, git
- **Kubernetes/Cloud:** kubectl, terraform, aws, az, gcloud
- **Language Runtimes:** nodejs, python, go, rust
- **Compression Tools:** 7zip, unzip
- **Media Tools:** ffmpeg, imagemagick
- **LaTeX:** texlive, miktex

**Installation:**

```powershell
# Install Scoop first (if not installed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install packages
scoop install docker kubectl terraform aws azure-cli gcloud bat fd httpie zoxide delta tldr procs dust
```

### NPM Packages

NPM packages are checked using `Test-NpmPackageAvailable` from `TestSupport/TestNpmHelpers.ps1`. The function supports both npm and pnpm global installations.

**Common Packages:**

- **superjson** - JSON serialization
- **@msgpack/msgpack** - MessagePack support
- **bson** - BSON format support
- **cbor** - CBOR format support
- **qrcode** - QR code generation
- **jimp** - Image processing

**Installation:**

```powershell
# Using npm
npm install -g superjson @msgpack/msgpack bson cbor qrcode jimp

# Using pnpm
pnpm add -g superjson @msgpack/msgpack bson cbor qrcode jimp
```

## Test Patterns

### Pattern 1: Using Test-ToolAvailable

```powershell
It 'Tests docker functionality' {
    $docker = Test-ToolAvailable -ToolName 'docker' -InstallCommand 'scoop install docker' -Silent
    if (-not $docker.Available) {
        Set-ItResult -Skipped -Because "docker not available. Install with: $($docker.InstallCommand)"
        return
    }

    # Test docker functionality
    docker --version | Should -Not -BeNullOrEmpty
}
```

### Pattern 2: Using Mock-CommandAvailabilityPester

```powershell
It 'Tests function when tool is unavailable' {
    Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It

    # Test that function handles missing tool gracefully
    { Get-DockerInfo } | Should -Not -Throw
}
```

### Pattern 3: Using Package Helpers

```powershell
It 'Tests Python package functionality' {
    if (-not (Test-PythonPackageAvailable -PackageName 'pandas')) {
        Set-ItResult -Skipped -Because "pandas package not available. Install with: pip install pandas"
        return
    }

    # Test pandas functionality
    # ...
}
```

## Installation Scripts

### Quick Install (Windows with Scoop)

```powershell
# Install Scoop (if not installed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install all recommended tools
scoop install docker kubectl terraform aws azure-cli gcloud bat fd httpie zoxide delta tldr procs dust gh git

# Install Python packages
pip install ion-python pyodbc dbfread dbf pyreadstat pandas scipy astropy pyarrow delta-spark deltalake pyiceberg python-snappy h5py netCDF4 numpy

# Install NPM packages
npm install -g superjson @msgpack/msgpack bson cbor qrcode jimp pnpm
```

### Check Missing Tools

```powershell
# In PowerShell, load TestSupport
. tests/TestSupport.ps1

# Get list of missing tools
$missing = Get-MissingTools
if ($missing) {
    Write-Host "Missing tools:"
    $missing | Format-Table Name, InstallCommand, InstallUrl
}

# Show all tool recommendations
Show-ToolRecommendations

# Show only missing tools
Show-ToolRecommendations -MissingOnly
```

## Test Coverage Impact

- **With all tools installed:** Full test coverage (599+ tests)
- **With minimal tools (PowerShell, Pester, Git):** Core tests pass (500+ tests)
- **With optional tools:** Additional integration tests enabled

Tests gracefully skip when tools are missing, so the test suite will always run successfully regardless of which tools are installed.

## Troubleshooting

### Tool Not Detected

1. Ensure the tool is in your PATH
2. Restart PowerShell after installing tools
3. Check tool availability: `Get-Command <tool-name> -ErrorAction SilentlyContinue`

### Package Not Detected

1. **Python packages:** Ensure Python/UV is in PATH and package is installed
2. **Scoop packages:** Ensure Scoop is installed and package is listed: `scoop list <package>`
3. **NPM packages:** Ensure Node.js is in PATH and package is globally installed

### Test Skipping Unexpectedly

Check the skip message - it will indicate which tool/package is missing and how to install it.
