# Requirements Configuration

This directory contains the modular requirements configuration structure for the PowerShell profile project.

## Structure

```
requirements/
├── modules.psd1                    # PowerShell modules (PSScriptAnalyzer, Pester, etc.)
├── platform.psd1                   # Platform-specific requirements
├── load-requirements.ps1          # Loader script that combines all modules
└── external-tools/                # External tool dependencies by category
    ├── code-quality.psd1          # Code quality tools (cspell, markdownlint-cli, git-cliff)
    ├── containers.psd1            # Container tools (docker, podman, etc.)
    ├── cli-tools.psd1             # Modern CLI tools (bat, fd, httpie, etc.)
    ├── kubernetes-cloud.psd1     # Kubernetes & cloud tools (kubectl, helm, terraform, aws, az, gcloud)
    ├── git-tools.psd1             # Git tools (gh)
    ├── file-data.psd1             # File & data tools (jq, yq, rclone, mc, zstd)
    ├── language-runtimes.psd1     # Language runtimes (bun, deno, go, rustup, uv, pixi)
    ├── other-tools.psd1           # Other tools (ollama, ngrok, firebase, tailscale, starship, oh-my-posh)
    ├── specialized-formats.psd1   # Specialized format tools (qrcode, jsonwebtoken, jsbarcode, canvas)
    └── document-formats.psd1      # Document format tools (pandoc, calibre, djvulibre, ImageMagick)
```

## Usage

### Loading Requirements in Scripts

**Recommended approach** (uses helper module):

```powershell
Import-Module RequirementsLoader
$requirements = Import-Requirements -RepoRoot $repoRoot
```

**Direct script execution**:

```powershell
$requirements = & (Join-Path $repoRoot 'requirements' 'load-requirements.ps1')
```

**Using RequirementsLoader module** (recommended, with caching):

```powershell
Import-Module (Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'RequirementsLoader.psm1')
$requirements = Import-Requirements -RepoRoot $repoRoot -UseCache
```

### Adding New Tools

1. Identify the appropriate category file in `external-tools/`
2. Add the tool definition following the existing format:
   ```powershell
   'tool-name' = @{
       Version        = 'latest'
       Description    = 'Tool description'
       Required       = $false
       InstallCommand = @{
           Windows = 'scoop install tool-name'
           Linux   = 'apt install tool-name'
           MacOS   = 'brew install tool-name'
       }
   }
   ```
3. The loader script will automatically include it in the combined requirements

### Adding New Categories

1. Create a new `.psd1` file in `external-tools/` directory
2. Follow the format of existing files (wrapped in `@{ ExternalTools = @{ ... } }`)
3. Add the category to `load-requirements.ps1`:
   ```powershell
   # New Category Tools
   $newCategoryPath = Join-Path $scriptDir 'external-tools' 'new-category.psd1'
   if (-not (Test-Path $newCategoryPath)) {
       throw "New category file not found: $newCategoryPath"
   }
   $newCategoryConfig = Import-PowerShellDataFile $newCategoryPath
   foreach ($tool in $newCategoryConfig.ExternalTools.Keys) {
       $ExternalTools[$tool] = $newCategoryConfig.ExternalTools[$tool]
   }
   ```

## Benefits

- **Modular**: Each category is in its own file, making it easy to find and update specific tools
- **Organized**: Tools are grouped by purpose (containers, CLI tools, cloud tools, etc.)
- **Maintainable**: Changes to one category don't affect others
- **Scalable**: Easy to add new categories or tools
- **Fully Modular**: All requirements are organized by category in separate files

## Migration Status

- ✅ Modular structure created
- ✅ Loader script implemented
- ✅ Helper module (`RequirementsLoader.psm1`) created
- ✅ Main dependency validator updated
- ✅ Error handling improved
- ✅ Modular structure fully implemented
