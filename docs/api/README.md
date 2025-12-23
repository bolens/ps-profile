# PowerShell Profile API Documentation

This documentation is automatically generated from comment-based help in the profile functions and aliases.

**Total Functions:** 176
**Total Aliases:** 278
**Generated:** 2025-12-02 20:25:57

## Functions by Fragment


### 02-files-module-registry (1 functions)

- [Load-EnsureModules](functions/Load-EnsureModules.md) - Loads modules for a specific Ensure function from the registry.

### 02-files (8 functions)

- [Ensure-DevTools](functions/Ensure-DevTools.md) - Initializes dev tools utility functions on first use.
- [Ensure-FileConversion-Data](functions/Ensure-FileConversion-Data.md) - Initializes data format conversion utility functions on first use.
- [Ensure-FileConversion-Documents](functions/Ensure-FileConversion-Documents.md) - Initializes document format conversion utility functions on first use.
- [Ensure-FileConversion-Media](functions/Ensure-FileConversion-Media.md) - Initializes media format conversion utility functions on first use.
- [Ensure-FileConversion-Specialized](functions/Ensure-FileConversion-Specialized.md) - Initializes specialized format conversion utility functions on first use.
- [Ensure-FileUtilities](functions/Ensure-FileUtilities.md) - Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads file utility modules from the files-modules subdirectory.
- [Import-FragmentModule](functions/Import-FragmentModule.md) - Loads a module file with consistent error handling.
- [Write-SubModuleError](functions/Write-SubModuleError.md) - Provides consistent error handling when loading sub-modules.

### 06-oh-my-posh (2 functions)

- [Initialize-OhMyPosh](functions/Initialize-OhMyPosh.md) - Initializes oh-my-posh prompt framework lazily.
- [prompt](functions/prompt.md) - PowerShell prompt function with lazy oh-my-posh initialization.

### 08-system-info (5 functions)

- [Get-BatteryInfo](functions/Get-BatteryInfo.md) - Shows battery information.
- [Get-CpuInfo](functions/Get-CpuInfo.md) - Shows CPU information.
- [Get-MemoryInfo](functions/Get-MemoryInfo.md) - Shows memory information.
- [Get-SystemInfo](functions/Get-SystemInfo.md) - Shows system information.
- [Get-SystemUptime](functions/Get-SystemUptime.md) - Shows system uptime.

### 09-package-managers (21 functions)

- [Add-PnpmDevPackage](functions/Add-PnpmDevPackage.md) - Adds dev dependencies using PNPM.
- [Add-PnpmPackage](functions/Add-PnpmPackage.md) - Adds packages using PNPM.
- [Add-UVDependency](functions/Add-UVDependency.md) - Adds dependencies to UV project.
- [Build-PnpmProject](functions/Build-PnpmProject.md) - Builds the project using PNPM.
- [Clear-ScoopCache](functions/Clear-ScoopCache.md) - Cleans up Scoop cache and old versions.
- [Find-ScoopPackage](functions/Find-ScoopPackage.md) - Searches for packages in Scoop.
- [Get-ScoopPackage](functions/Get-ScoopPackage.md) - Lists installed Scoop packages.
- [Get-ScoopPackageInfo](functions/Get-ScoopPackageInfo.md) - Shows information about Scoop packages.
- [Install-PnpmPackage](functions/Install-PnpmPackage.md) - Installs dependencies using PNPM.
- [Install-ScoopPackage](functions/Install-ScoopPackage.md) - Installs packages using Scoop.
- [Install-UVTool](functions/Install-UVTool.md) - Installs Python tools using UV.
- [Invoke-PnpmScript](functions/Invoke-PnpmScript.md) - Runs scripts using PNPM.
- [Invoke-UVRun](functions/Invoke-UVRun.md) - Runs Python commands with UV.
- [Invoke-UVTool](functions/Invoke-UVTool.md) - Runs tools installed with UV.
- [Start-PnpmDev](functions/Start-PnpmDev.md) - Runs development server using PNPM.
- [Start-PnpmProject](functions/Start-PnpmProject.md) - Starts the project using PNPM.
- [Sync-UVDependencies](functions/Sync-UVDependencies.md) - Syncs UV project dependencies.
- [Test-PnpmProject](functions/Test-PnpmProject.md) - Runs tests using PNPM.
- [Uninstall-ScoopPackage](functions/Uninstall-ScoopPackage.md) - Uninstalls packages using Scoop.
- [Update-ScoopAll](functions/Update-ScoopAll.md) - Updates all installed Scoop packages.
- [Update-ScoopPackage](functions/Update-ScoopPackage.md) - Updates packages using Scoop.

### 10-wsl (3 functions)

- [Get-WSLDistribution](functions/Get-WSLDistribution.md) - Lists all WSL distributions with their status.
- [Start-UbuntuWSL](functions/Start-UbuntuWSL.md) - Launches or switches to Ubuntu WSL distribution.
- [Stop-WSL](functions/Stop-WSL.md) - Shuts down all WSL distributions.

### 13-ansible (6 functions)

- [Get-AnsibleDoc](functions/Get-AnsibleDoc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale.
- [Get-AnsibleInventory](functions/Get-AnsibleInventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale.
- [Invoke-Ansible](functions/Invoke-Ansible.md) - Runs Ansible commands via WSL with UTF-8 locale.
- [Invoke-AnsibleGalaxy](functions/Invoke-AnsibleGalaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale.
- [Invoke-AnsiblePlaybook](functions/Invoke-AnsiblePlaybook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale.
- [Invoke-AnsibleVault](functions/Invoke-AnsibleVault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale.

### 15-shortcuts (3 functions)

- [Get-ProjectRoot](functions/Get-ProjectRoot.md) - Changes to project root directory.
- [Open-Editor](functions/Open-Editor.md) - Opens file in the best available editor.
- [Open-VSCode](functions/Open-VSCode.md) - Opens current directory in the best available editor.

### 16-clipboard (2 functions)

- [Copy-ToClipboard](functions/Copy-ToClipboard.md) - Copies input to the clipboard.
- [Get-FromClipboard](functions/Get-FromClipboard.md) - Pastes content from the clipboard.

### 17-kubectl (5 functions)

- [Describe-KubectlResource](functions/Describe-KubectlResource.md) - Describes Kubernetes resources.
- [Get-KubectlContext](functions/Get-KubectlContext.md) - Gets the current Kubernetes context.
- [Get-KubectlResource](functions/Get-KubectlResource.md) - Gets Kubernetes resources.
- [Invoke-Kubectl](functions/Invoke-Kubectl.md) - Executes kubectl with the specified arguments.
- [Set-KubectlContext](functions/Set-KubectlContext.md) - Switches the current Kubernetes context.

### 18-terraform (5 functions)

- [Get-TerraformPlan](functions/Get-TerraformPlan.md) - Creates a Terraform execution plan.
- [Initialize-Terraform](functions/Initialize-Terraform.md) - Initializes a Terraform working directory.
- [Invoke-Terraform](functions/Invoke-Terraform.md) - Executes terraform with the specified arguments.
- [Invoke-TerraformApply](functions/Invoke-TerraformApply.md) - Applies Terraform changes.
- [Remove-TerraformInfrastructure](functions/Remove-TerraformInfrastructure.md) - Destroys Terraform-managed infrastructure.

### 19-fzf (2 functions)

- [Find-CommandFuzzy](functions/Find-CommandFuzzy.md) - Finds PowerShell commands using fzf fuzzy finder.
- [Find-FileFuzzy](functions/Find-FileFuzzy.md) - Finds files using fzf fuzzy finder.

### 20-gh (2 functions)

- [Invoke-GitHubPullRequest](functions/Invoke-GitHubPullRequest.md) - Manages GitHub pull requests.
- [Open-GitHubRepository](functions/Open-GitHubRepository.md) - Opens a GitHub repository in the web browser.

### 21-kube (2 functions)

- [Start-MinikubeCluster](functions/Start-MinikubeCluster.md) - Starts a Minikube cluster.
- [Stop-MinikubeCluster](functions/Stop-MinikubeCluster.md) - Stops a Minikube cluster.

### 25-lazydocker (1 functions)

- [Invoke-LazyDocker](functions/Invoke-LazyDocker.md) - Launches lazydocker terminal UI.

### 26-rclone (2 functions)

- [Copy-RcloneFile](functions/Copy-RcloneFile.md) - Copies files using rclone.
- [Get-RcloneFileList](functions/Get-RcloneFileList.md) - Lists files using rclone.

### 27-minio (2 functions)

- [Copy-MinioFile](functions/Copy-MinioFile.md) - Copies files using MinIO client.
- [Get-MinioFileList](functions/Get-MinioFileList.md) - Lists files in MinIO storage.

### 28-jq-yq (2 functions)

- [Convert-JqToJson](functions/Convert-JqToJson.md) - Converts JSON to compact JSON format using jq.
- [Convert-YqToJson](functions/Convert-YqToJson.md) - Converts YAML to JSON format using yq.

### 29-rg (1 functions)

- [Find-RipgrepText](functions/Find-RipgrepText.md) - Finds text using ripgrep with common options.

### 30-open (1 functions)

- [Open-Item](functions/Open-Item.md) - Opens files or URLs using the system's default application.

### 31-aws (3 functions)

- [Invoke-Aws](functions/Invoke-Aws.md) - Executes AWS CLI commands.
- [Set-AwsProfile](functions/Set-AwsProfile.md) - Sets the AWS profile environment variable.
- [Set-AwsRegion](functions/Set-AwsRegion.md) - Sets the AWS region environment variable.

### 32-bun (3 functions)

- [Add-BunPackage](functions/Add-BunPackage.md) - Adds packages using Bun.
- [Invoke-BunRun](functions/Invoke-BunRun.md) - Runs npm scripts using Bun.
- [Invoke-Bunx](functions/Invoke-Bunx.md) - Executes packages using bunx.

### 33-aliases (1 functions)

- [Enable-Aliases](functions/Enable-Aliases.md) - Enables user-defined aliases and helper functions for enhanced shell experience.

### 35-ollama (4 functions)

- [Get-OllamaModel](functions/Get-OllamaModel.md) - Downloads an Ollama model.
- [Get-OllamaModelList](functions/Get-OllamaModelList.md) - Lists available Ollama models.
- [Invoke-Ollama](functions/Invoke-Ollama.md) - Executes Ollama commands.
- [Start-OllamaModel](functions/Start-OllamaModel.md) - Runs an Ollama model interactively.

### 36-ngrok (3 functions)

- [Invoke-Ngrok](functions/Invoke-Ngrok.md) - Executes Ngrok commands.
- [Start-NgrokHttpTunnel](functions/Start-NgrokHttpTunnel.md) - Creates an Ngrok HTTP tunnel.
- [Start-NgrokTcpTunnel](functions/Start-NgrokTcpTunnel.md) - Creates an Ngrok TCP tunnel.

### 37-deno (3 functions)

- [Invoke-Deno](functions/Invoke-Deno.md) - Executes Deno commands.
- [Invoke-DenoRun](functions/Invoke-DenoRun.md) - Runs Deno scripts.
- [Invoke-DenoTask](functions/Invoke-DenoTask.md) - Runs Deno tasks.

### 38-firebase (3 functions)

- [Invoke-Firebase](functions/Invoke-Firebase.md) - Executes Firebase CLI commands.
- [Publish-FirebaseDeployment](functions/Publish-FirebaseDeployment.md) - Deploys to Firebase hosting.
- [Start-FirebaseServer](functions/Start-FirebaseServer.md) - Starts Firebase local development server.

### 39-rustup (3 functions)

- [Install-RustupToolchain](functions/Install-RustupToolchain.md) - Installs Rust toolchains.
- [Invoke-Rustup](functions/Invoke-Rustup.md) - Executes Rustup commands.
- [Update-RustupToolchain](functions/Update-RustupToolchain.md) - Updates the Rust toolchain.

### 40-tailscale (4 functions)

- [Connect-TailscaleNetwork](functions/Connect-TailscaleNetwork.md) - Connects to the Tailscale network.
- [Disconnect-TailscaleNetwork](functions/Disconnect-TailscaleNetwork.md) - Disconnects from the Tailscale network.
- [Get-TailscaleStatus](functions/Get-TailscaleStatus.md) - Gets Tailscale connection status.
- [Invoke-Tailscale](functions/Invoke-Tailscale.md) - Executes Tailscale commands.

### 41-yarn (3 functions)

- [Add-YarnPackage](functions/Add-YarnPackage.md) - Adds packages to project dependencies.
- [Install-YarnDependencies](functions/Install-YarnDependencies.md) - Installs project dependencies.
- [Invoke-Yarn](functions/Invoke-Yarn.md) - Executes Yarn commands.

### 42-php (3 functions)

- [Invoke-Composer](functions/Invoke-Composer.md) - Executes Composer commands.
- [Invoke-Php](functions/Invoke-Php.md) - Executes PHP commands.
- [Start-PhpServer](functions/Start-PhpServer.md) - Starts PHP built-in development server.

### 43-laravel (3 functions)

- [Invoke-LaravelArt](functions/Invoke-LaravelArt.md) - Executes Laravel Artisan commands (alias).
- [Invoke-LaravelArtisan](functions/Invoke-LaravelArtisan.md) - Executes Laravel Artisan commands.
- [New-LaravelApp](functions/New-LaravelApp.md) - Creates a new Laravel application.

### 45-nextjs (4 functions)

- [Build-NextJsApp](functions/Build-NextJsApp.md) - Builds Next.js application for production.
- [New-NextJsApp](functions/New-NextJsApp.md) - Creates a new Next.js application.
- [Start-NextJsDev](functions/Start-NextJsDev.md) - Starts Next.js development server.
- [Start-NextJsProduction](functions/Start-NextJsProduction.md) - Starts Next.js production server.

### 46-vite (4 functions)

- [Build-ViteApp](functions/Build-ViteApp.md) - Builds Vite application for production.
- [Invoke-Vite](functions/Invoke-Vite.md) - Executes Vite commands.
- [New-ViteProject](functions/New-ViteProject.md) - Creates a new Vite project.
- [Start-ViteDev](functions/Start-ViteDev.md) - Starts Vite development server.

### 47-angular (3 functions)

- [Invoke-Angular](functions/Invoke-Angular.md) - Executes Angular CLI commands.
- [New-AngularApp](functions/New-AngularApp.md) - Creates a new Angular application.
- [Start-AngularDev](functions/Start-AngularDev.md) - Starts Angular development server.

### 48-vue (3 functions)

- [Invoke-Vue](functions/Invoke-Vue.md) - Executes Vue CLI commands.
- [New-VueApp](functions/New-VueApp.md) - Creates a new Vue.js project.
- [Start-VueDev](functions/Start-VueDev.md) - Starts Vue.js development server.

### 49-nuxt (4 functions)

- [Build-NuxtApp](functions/Build-NuxtApp.md) - Builds Nuxt.js application for production.
- [Invoke-Nuxt](functions/Invoke-Nuxt.md) - Executes Nuxt CLI (nuxi) commands.
- [New-NuxtApp](functions/New-NuxtApp.md) - Creates a new Nuxt.js application.
- [Start-NuxtDev](functions/Start-NuxtDev.md) - Starts Nuxt.js development server.

### 50-azure (4 functions)

- [Connect-AzureAccount](functions/Connect-AzureAccount.md) - Authenticates with Azure CLI.
- [Invoke-Azure](functions/Invoke-Azure.md) - Executes Azure CLI commands.
- [Invoke-AzureDeveloper](functions/Invoke-AzureDeveloper.md) - Executes Azure Developer CLI commands.
- [Start-AzureDeveloperUp](functions/Start-AzureDeveloperUp.md) - Provisions and deploys using Azure Developer CLI.

### 51-gcloud (4 functions)

- [Get-GCloudProjects](functions/Get-GCloudProjects.md) - Manages Google Cloud Platform projects.
- [Invoke-GCloud](functions/Invoke-GCloud.md) - Executes Google Cloud CLI commands.
- [Set-GCloudAuth](functions/Set-GCloudAuth.md) - Manages Google Cloud authentication.
- [Set-GCloudConfig](functions/Set-GCloudConfig.md) - Manages Google Cloud configuration.

### 52-helm (4 functions)

- [Get-HelmReleases](functions/Get-HelmReleases.md) - Lists Helm releases.
- [Install-HelmChart](functions/Install-HelmChart.md) - Installs Helm charts.
- [Invoke-Helm](functions/Invoke-Helm.md) - Executes Helm commands.
- [Update-HelmRelease](functions/Update-HelmRelease.md) - Upgrades Helm releases.

### 53-go (4 functions)

- [Build-GoProgram](functions/Build-GoProgram.md) - Builds Go programs.
- [Invoke-GoModule](functions/Invoke-GoModule.md) - Manages Go modules.
- [Invoke-GoRun](functions/Invoke-GoRun.md) - Runs Go programs.
- [Test-GoPackage](functions/Test-GoPackage.md) - Runs Go tests.

### 61-eza (11 functions)

- [Get-ChildItemEza](functions/Get-ChildItemEza.md) - Lists directory contents using eza.
- [Get-ChildItemEzaAll](functions/Get-ChildItemEzaAll.md) - Lists all directory contents including hidden files using eza.
- [Get-ChildItemEzaAllLong](functions/Get-ChildItemEzaAllLong.md) - Lists all directory contents in long format using eza.
- [Get-ChildItemEzaBySize](functions/Get-ChildItemEzaBySize.md) - Lists directory contents sorted by size using eza.
- [Get-ChildItemEzaByTime](functions/Get-ChildItemEzaByTime.md) - Lists directory contents sorted by modification time using eza.
- [Get-ChildItemEzaGit](functions/Get-ChildItemEzaGit.md) - Lists directory contents with git status using eza.
- [Get-ChildItemEzaLong](functions/Get-ChildItemEzaLong.md) - Lists directory contents in long format using eza.
- [Get-ChildItemEzaLongGit](functions/Get-ChildItemEzaLongGit.md) - Lists directory contents in long format with git status using eza.
- [Get-ChildItemEzaShort](functions/Get-ChildItemEzaShort.md) - Lists directory contents using eza (short alias).
- [Get-ChildItemEzaTree](functions/Get-ChildItemEzaTree.md) - Lists directory contents in tree format using eza.
- [Get-ChildItemEzaTreeAll](functions/Get-ChildItemEzaTreeAll.md) - Lists all directory contents in tree format using eza.

### 62-navi (3 functions)

- [Invoke-NaviBest](functions/Invoke-NaviBest.md) - Finds the best matching command from navi cheatsheets.
- [Invoke-NaviPrint](functions/Invoke-NaviPrint.md) - Prints commands from navi cheatsheets without executing them.
- [Invoke-NaviSearch](functions/Invoke-NaviSearch.md) - Searches navi cheatsheets interactively.

### 63-gum (5 functions)

- [Invoke-GumChoose](functions/Invoke-GumChoose.md) - Shows an interactive selection menu using gum.
- [Invoke-GumConfirm](functions/Invoke-GumConfirm.md) - Shows a confirmation prompt using gum.
- [Invoke-GumInput](functions/Invoke-GumInput.md) - Shows an input prompt using gum.
- [Invoke-GumSpin](functions/Invoke-GumSpin.md) - Shows a spinner while executing a script block using gum.
- [Invoke-GumStyle](functions/Invoke-GumStyle.md) - Styles text output using gum.

### 67-uv (4 functions)

- [Install-UVTool](functions/Install-UVTool.md) - Installs Python tools globally using uv.
- [Invoke-Pip](functions/Invoke-Pip.md) - Python package manager using uv instead of pip.
- [Invoke-UVRun](functions/Invoke-UVRun.md) - Runs Python commands in temporary virtual environments using uv.
- [New-UVVenv](functions/New-UVVenv.md) - Creates Python virtual environments using uv.

### 68-pixi (3 functions)

- [Invoke-PixiInstall](functions/Invoke-PixiInstall.md) - Installs packages using pixi.
- [Invoke-PixiRun](functions/Invoke-PixiRun.md) - Runs commands in the pixi environment.
- [Invoke-PixiShell](functions/Invoke-PixiShell.md) - Activates the pixi shell environment.

### 69-pnpm (3 functions)

- [Invoke-PnpmDevInstall](functions/Invoke-PnpmDevInstall.md) - Installs development packages using pnpm.
- [Invoke-PnpmInstall](functions/Invoke-PnpmInstall.md) - Installs packages using pnpm.
- [Invoke-PnpmRun](functions/Invoke-PnpmRun.md) - Runs npm scripts using pnpm.

### 70-profile-updates (1 functions)

- [Test-ProfileUpdates](functions/Test-ProfileUpdates.md) - Checks for profile updates and displays changelog.


## Aliases by Fragment


### 08-system-info (5 aliases)

- [battery](aliases/battery.md) - Shows battery information. (alias for `Get-BatteryInfo`)
- [cpuinfo](aliases/cpuinfo.md) - Shows CPU information. (alias for `Get-CpuInfo`)
- [meminfo](aliases/meminfo.md) - Shows memory information. (alias for `Get-MemoryInfo`)
- [sysinfo](aliases/sysinfo.md) - Shows system information. (alias for `Get-SystemInfo`)
- [uptime](aliases/uptime.md) - Shows system uptime. (alias for `Get-SystemUptime`)

### 09-package-managers (21 aliases)

- [pna](aliases/pna.md) - Adds packages using PNPM. (alias for `Add-PnpmPackage`)
- [pnb](aliases/pnb.md) - Builds the project using PNPM. (alias for `Build-PnpmProject`)
- [pnd](aliases/pnd.md) - Adds dev dependencies using PNPM. (alias for `Add-PnpmDevPackage`)
- [pndev](aliases/pndev.md) - Runs development server using PNPM. (alias for `Start-PnpmDev`)
- [pni](aliases/pni.md) - Installs dependencies using PNPM. (alias for `Install-PnpmPackage`)
- [pnr](aliases/pnr.md) - Runs scripts using PNPM. (alias for `Invoke-PnpmScript`)
- [pns](aliases/pns.md) - Starts the project using PNPM. (alias for `Start-PnpmProject`)
- [pnt](aliases/pnt.md) - Runs tests using PNPM. (alias for `Test-PnpmProject`)
- [scleanup](aliases/scleanup.md) - Cleans up Scoop cache and old versions. (alias for `Clear-ScoopCache`)
- [sh](aliases/sh.md) - Shows information about Scoop packages. (alias for `Get-ScoopPackageInfo`)
- [sinstall](aliases/sinstall.md) - Installs packages using Scoop. (alias for `Install-ScoopPackage`)
- [slist](aliases/slist.md) - Lists installed Scoop packages. (alias for `Get-ScoopPackage`)
- [sr](aliases/sr.md) - Uninstalls packages using Scoop. (alias for `Uninstall-ScoopPackage`)
- [ss](aliases/ss.md) - Searches for packages in Scoop. (alias for `Find-ScoopPackage`)
- [su](aliases/su.md) - Updates packages using Scoop. (alias for `Update-ScoopPackage`)
- [suu](aliases/suu.md) - Updates all installed Scoop packages. (alias for `Update-ScoopAll`)
- [uva](aliases/uva.md) - Adds dependencies to UV project. (alias for `Add-UVDependency`)
- [uvi](aliases/uvi.md) - Installs Python tools using UV. (alias for `Install-UVTool`)
- [uvr](aliases/uvr.md) - Runs Python commands with UV. (alias for `Invoke-UVRun`)
- [uvs](aliases/uvs.md) - Syncs UV project dependencies. (alias for `Sync-UVDependencies`)
- [uvx](aliases/uvx.md) - Runs tools installed with UV. (alias for `Invoke-UVTool`)

### 10-wsl (3 aliases)

- [ubuntu](aliases/ubuntu.md) - Launches or switches to Ubuntu WSL distribution. (alias for `Start-UbuntuWSL`)
- [wsl-list](aliases/wsl-list.md) - Lists all WSL distributions with their status. (alias for `Get-WSLDistribution`)
- [wsl-shutdown](aliases/wsl-shutdown.md) - Shuts down all WSL distributions. (alias for `Stop-WSL`)

### 13-ansible (12 aliases)

- [ansible](aliases/ansible.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Invoke-Ansible`)
- [ansible](aliases/ansible.md) - Runs Ansible commands via WSL with UTF-8 locale. (alias for `Invoke-Ansible`)
- [ansible-doc](aliases/ansible-doc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale. (alias for `Get-AnsibleDoc`)
- [ansible-doc](aliases/ansible-doc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale. (alias for `Get-AnsibleDoc`)
- [ansible-galaxy](aliases/ansible-galaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleGalaxy`)
- [ansible-galaxy](aliases/ansible-galaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleGalaxy`)
- [ansible-inventory](aliases/ansible-inventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Get-AnsibleInventory`)
- [ansible-inventory](aliases/ansible-inventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Get-AnsibleInventory`)
- [ansible-playbook](aliases/ansible-playbook.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Invoke-AnsiblePlaybook`)
- [ansible-playbook](aliases/ansible-playbook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale. (alias for `Invoke-AnsiblePlaybook`)
- [ansible-vault](aliases/ansible-vault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleVault`)
- [ansible-vault](aliases/ansible-vault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleVault`)

### 14-ssh (3 aliases)

- [ssh-add-if](aliases/ssh-add-if.md) - Alias for `Add-SSHKeyIfNotLoaded` (alias for `Add-SSHKeyIfNotLoaded`)
- [ssh-agent-start](aliases/ssh-agent-start.md) - Alias for `Start-SSHAgent` (alias for `Start-SSHAgent`)
- [ssh-list](aliases/ssh-list.md) - Alias for `Get-SSHKeys` (alias for `Get-SSHKeys`)

### 15-shortcuts (4 aliases)

- [code](aliases/code.md) - Opens current directory in the best available editor. (alias for `Open-VSCode`)
- [e](aliases/e.md) - Opens file in the best available editor. (alias for `Open-Editor`)
- [project-root](aliases/project-root.md) - Changes to project root directory. (alias for `Get-ProjectRoot`)
- [vsc](aliases/vsc.md) - Opens current directory in the best available editor. (alias for `Open-VSCode`)

### 16-clipboard (2 aliases)

- [cb](aliases/cb.md) - Copies input to the clipboard. (alias for `Copy-ToClipboard`)
- [pb](aliases/pb.md) - Pastes content from the clipboard. (alias for `Get-FromClipboard`)

### 17-kubectl (10 aliases)

- [k](aliases/k.md) - Gets the current Kubernetes context. (alias for `Invoke-Kubectl`)
- [k](aliases/k.md) - Executes kubectl with the specified arguments. (alias for `Invoke-Kubectl`)
- [kctx](aliases/kctx.md) - Gets the current Kubernetes context. (alias for `Get-KubectlContext`)
- [kctx](aliases/kctx.md) - Gets the current Kubernetes context. (alias for `Get-KubectlContext`)
- [kd](aliases/kd.md) - Gets the current Kubernetes context. (alias for `Describe-KubectlResource`)
- [kd](aliases/kd.md) - Describes Kubernetes resources. (alias for `Describe-KubectlResource`)
- [kg](aliases/kg.md) - Gets the current Kubernetes context. (alias for `Get-KubectlResource`)
- [kg](aliases/kg.md) - Gets Kubernetes resources. (alias for `Get-KubectlResource`)
- [kn](aliases/kn.md) - Gets the current Kubernetes context. (alias for `Set-KubectlContext`)
- [kn](aliases/kn.md) - Switches the current Kubernetes context. (alias for `Set-KubectlContext`)

### 18-terraform (10 aliases)

- [tf](aliases/tf.md) - Executes terraform with the specified arguments. (alias for `Invoke-Terraform`)
- [tf](aliases/tf.md) - Executes terraform with the specified arguments. (alias for `Invoke-Terraform`)
- [tfa](aliases/tfa.md) - Applies Terraform changes. (alias for `Invoke-TerraformApply`)
- [tfa](aliases/tfa.md) - Applies Terraform changes. (alias for `Invoke-TerraformApply`)
- [tfd](aliases/tfd.md) - Destroys Terraform-managed infrastructure. (alias for `Remove-TerraformInfrastructure`)
- [tfd](aliases/tfd.md) - Destroys Terraform-managed infrastructure. (alias for `Remove-TerraformInfrastructure`)
- [tfi](aliases/tfi.md) - Initializes a Terraform working directory. (alias for `Initialize-Terraform`)
- [tfi](aliases/tfi.md) - Initializes a Terraform working directory. (alias for `Initialize-Terraform`)
- [tfp](aliases/tfp.md) - Creates a Terraform execution plan. (alias for `Get-TerraformPlan`)
- [tfp](aliases/tfp.md) - Creates a Terraform execution plan. (alias for `Get-TerraformPlan`)

### 19-fzf (4 aliases)

- [fcmd](aliases/fcmd.md) - Finds PowerShell commands using fzf fuzzy finder. (alias for `Find-CommandFuzzy`)
- [fcmd](aliases/fcmd.md) - Finds PowerShell commands using fzf fuzzy finder. (alias for `Find-CommandFuzzy`)
- [ff](aliases/ff.md) - Finds PowerShell commands using fzf fuzzy finder. (alias for `Find-FileFuzzy`)
- [ff](aliases/ff.md) - Finds PowerShell commands using fzf fuzzy finder. (alias for `Find-FileFuzzy`)

### 20-gh (4 aliases)

- [gh-open](aliases/gh-open.md) - Opens a GitHub repository in the web browser. (alias for `Open-GitHubRepository`)
- [gh-open](aliases/gh-open.md) - Opens a GitHub repository in the web browser. (alias for `Open-GitHubRepository`)
- [gh-pr](aliases/gh-pr.md) - Manages GitHub pull requests. (alias for `Invoke-GitHubPullRequest`)
- [gh-pr](aliases/gh-pr.md) - Manages GitHub pull requests. (alias for `Invoke-GitHubPullRequest`)

### 21-kube (4 aliases)

- [minikube-start](aliases/minikube-start.md) - Starts a Minikube cluster. (alias for `Start-MinikubeCluster`)
- [minikube-start](aliases/minikube-start.md) - Starts a Minikube cluster. (alias for `Start-MinikubeCluster`)
- [minikube-stop](aliases/minikube-stop.md) - Stops a Minikube cluster. (alias for `Stop-MinikubeCluster`)
- [minikube-stop](aliases/minikube-stop.md) - Stops a Minikube cluster. (alias for `Stop-MinikubeCluster`)

### 25-lazydocker (2 aliases)

- [ld](aliases/ld.md) - Launches lazydocker terminal UI. (alias for `Invoke-LazyDocker`)
- [ld](aliases/ld.md) - Launches lazydocker terminal UI. (alias for `Invoke-LazyDocker`)

### 26-rclone (4 aliases)

- [rcopy](aliases/rcopy.md) - Copies files using rclone. (alias for `Copy-RcloneFile`)
- [rcopy](aliases/rcopy.md) - Copies files using rclone. (alias for `Copy-RcloneFile`)
- [rls](aliases/rls.md) - Lists files using rclone. (alias for `Get-RcloneFileList`)
- [rls](aliases/rls.md) - Lists files using rclone. (alias for `Get-RcloneFileList`)

### 27-minio (4 aliases)

- [mc-cp](aliases/mc-cp.md) - Copies files using MinIO client. (alias for `Copy-MinioFile`)
- [mc-cp](aliases/mc-cp.md) - Copies files using MinIO client. (alias for `Copy-MinioFile`)
- [mc-ls](aliases/mc-ls.md) - Lists files in MinIO storage. (alias for `Get-MinioFileList`)
- [mc-ls](aliases/mc-ls.md) - Lists files in MinIO storage. (alias for `Get-MinioFileList`)

### 28-jq-yq (4 aliases)

- [jq2json](aliases/jq2json.md) - Converts JSON to compact JSON format using jq. (alias for `Convert-JqToJson`)
- [jq2json](aliases/jq2json.md) - Converts JSON to compact JSON format using jq. (alias for `Convert-JqToJson`)
- [yq2json](aliases/yq2json.md) - Converts YAML to JSON format using yq. (alias for `Convert-YqToJson`)
- [yq2json](aliases/yq2json.md) - Converts YAML to JSON format using yq. (alias for `Convert-YqToJson`)

### 29-rg (2 aliases)

- [rgf](aliases/rgf.md) - Finds text using ripgrep with common options. (alias for `Find-RipgrepText`)
- [rgf](aliases/rgf.md) - Finds text using ripgrep with common options. (alias for `Find-RipgrepText`)

### 30-open (1 aliases)

- [open](aliases/open.md) - Opens files or URLs using the system's default application. (alias for `Open-Item`)

### 31-aws (6 aliases)

- [aws](aliases/aws.md) - Executes AWS CLI commands. (alias for `Invoke-Aws`)
- [aws](aliases/aws.md) - Executes AWS CLI commands. (alias for `Invoke-Aws`)
- [aws-profile](aliases/aws-profile.md) - Sets the AWS profile environment variable. (alias for `Set-AwsProfile`)
- [aws-profile](aliases/aws-profile.md) - Sets the AWS profile environment variable. (alias for `Set-AwsProfile`)
- [aws-region](aliases/aws-region.md) - Sets the AWS region environment variable. (alias for `Set-AwsRegion`)
- [aws-region](aliases/aws-region.md) - Sets the AWS region environment variable. (alias for `Set-AwsRegion`)

### 32-bun (6 aliases)

- [bun-add](aliases/bun-add.md) - Adds packages using Bun. (alias for `Add-BunPackage`)
- [bun-add](aliases/bun-add.md) - Adds packages using Bun. (alias for `Add-BunPackage`)
- [bun-run](aliases/bun-run.md) - Runs npm scripts using Bun. (alias for `Invoke-BunRun`)
- [bun-run](aliases/bun-run.md) - Runs npm scripts using Bun. (alias for `Invoke-BunRun`)
- [bunx](aliases/bunx.md) - Executes packages using bunx. (alias for `Invoke-Bunx`)
- [bunx](aliases/bunx.md) - Executes packages using bunx. (alias for `Invoke-Bunx`)

### 33-aliases (2 aliases)

- [la](aliases/la.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhancedAll`)
- [ll](aliases/ll.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhanced`)

### 35-ollama (8 aliases)

- [ol](aliases/ol.md) - Executes Ollama commands. (alias for `Invoke-Ollama`)
- [ol](aliases/ol.md) - Executes Ollama commands. (alias for `Invoke-Ollama`)
- [ol-list](aliases/ol-list.md) - Lists available Ollama models. (alias for `Get-OllamaModelList`)
- [ol-list](aliases/ol-list.md) - Lists available Ollama models. (alias for `Get-OllamaModelList`)
- [ol-pull](aliases/ol-pull.md) - Downloads an Ollama model. (alias for `Get-OllamaModel`)
- [ol-pull](aliases/ol-pull.md) - Downloads an Ollama model. (alias for `Get-OllamaModel`)
- [ol-run](aliases/ol-run.md) - Runs an Ollama model interactively. (alias for `Start-OllamaModel`)
- [ol-run](aliases/ol-run.md) - Runs an Ollama model interactively. (alias for `Start-OllamaModel`)

### 36-ngrok (6 aliases)

- [ngrok](aliases/ngrok.md) - Executes Ngrok commands. (alias for `Invoke-Ngrok`)
- [ngrok](aliases/ngrok.md) - Executes Ngrok commands. (alias for `Invoke-Ngrok`)
- [ngrok-http](aliases/ngrok-http.md) - Creates an Ngrok HTTP tunnel. (alias for `Start-NgrokHttpTunnel`)
- [ngrok-http](aliases/ngrok-http.md) - Creates an Ngrok HTTP tunnel. (alias for `Start-NgrokHttpTunnel`)
- [ngrok-tcp](aliases/ngrok-tcp.md) - Creates an Ngrok TCP tunnel. (alias for `Start-NgrokTcpTunnel`)
- [ngrok-tcp](aliases/ngrok-tcp.md) - Creates an Ngrok TCP tunnel. (alias for `Start-NgrokTcpTunnel`)

### 37-deno (6 aliases)

- [deno](aliases/deno.md) - Executes Deno commands. (alias for `Invoke-Deno`)
- [deno](aliases/deno.md) - Executes Deno commands. (alias for `Invoke-Deno`)
- [deno-run](aliases/deno-run.md) - Runs Deno scripts. (alias for `Invoke-DenoRun`)
- [deno-run](aliases/deno-run.md) - Runs Deno scripts. (alias for `Invoke-DenoRun`)
- [deno-task](aliases/deno-task.md) - Runs Deno tasks. (alias for `Invoke-DenoTask`)
- [deno-task](aliases/deno-task.md) - Runs Deno tasks. (alias for `Invoke-DenoTask`)

### 38-firebase (6 aliases)

- [fb](aliases/fb.md) - Executes Firebase CLI commands. (alias for `Invoke-Firebase`)
- [fb](aliases/fb.md) - Executes Firebase CLI commands. (alias for `Invoke-Firebase`)
- [fb-deploy](aliases/fb-deploy.md) - Deploys to Firebase hosting. (alias for `Publish-FirebaseDeployment`)
- [fb-deploy](aliases/fb-deploy.md) - Deploys to Firebase hosting. (alias for `Publish-FirebaseDeployment`)
- [fb-serve](aliases/fb-serve.md) - Starts Firebase local development server. (alias for `Start-FirebaseServer`)
- [fb-serve](aliases/fb-serve.md) - Starts Firebase local development server. (alias for `Start-FirebaseServer`)

### 39-rustup (6 aliases)

- [rustup](aliases/rustup.md) - Executes Rustup commands. (alias for `Invoke-Rustup`)
- [rustup](aliases/rustup.md) - Executes Rustup commands. (alias for `Invoke-Rustup`)
- [rustup-install](aliases/rustup-install.md) - Installs Rust toolchains. (alias for `Install-RustupToolchain`)
- [rustup-install](aliases/rustup-install.md) - Installs Rust toolchains. (alias for `Install-RustupToolchain`)
- [rustup-update](aliases/rustup-update.md) - Updates the Rust toolchain. (alias for `Update-RustupToolchain`)
- [rustup-update](aliases/rustup-update.md) - Updates the Rust toolchain. (alias for `Update-RustupToolchain`)

### 40-tailscale (8 aliases)

- [tailscale](aliases/tailscale.md) - Gets Tailscale connection status. (alias for `Invoke-Tailscale`)
- [tailscale](aliases/tailscale.md) - Gets Tailscale connection status. (alias for `Invoke-Tailscale`)
- [ts-down](aliases/ts-down.md) - Gets Tailscale connection status. (alias for `Disconnect-TailscaleNetwork`)
- [ts-down](aliases/ts-down.md) - Disconnects from the Tailscale network. (alias for `Disconnect-TailscaleNetwork`)
- [ts-status](aliases/ts-status.md) - Gets Tailscale connection status. (alias for `Get-TailscaleStatus`)
- [ts-status](aliases/ts-status.md) - Gets Tailscale connection status. (alias for `Get-TailscaleStatus`)
- [ts-up](aliases/ts-up.md) - Gets Tailscale connection status. (alias for `Connect-TailscaleNetwork`)
- [ts-up](aliases/ts-up.md) - Connects to the Tailscale network. (alias for `Connect-TailscaleNetwork`)

### 41-yarn (6 aliases)

- [yarn](aliases/yarn.md) - Installs project dependencies. (alias for `Invoke-Yarn`)
- [yarn](aliases/yarn.md) - Installs project dependencies. (alias for `Invoke-Yarn`)
- [yarn-add](aliases/yarn-add.md) - Installs project dependencies. (alias for `Add-YarnPackage`)
- [yarn-add](aliases/yarn-add.md) - Installs project dependencies. (alias for `Add-YarnPackage`)
- [yarn-install](aliases/yarn-install.md) - Installs project dependencies. (alias for `Install-YarnDependencies`)
- [yarn-install](aliases/yarn-install.md) - Installs project dependencies. (alias for `Install-YarnDependencies`)

### 42-php (6 aliases)

- [composer](aliases/composer.md) - Executes Composer commands. (alias for `Invoke-Composer`)
- [composer](aliases/composer.md) - Executes Composer commands. (alias for `Invoke-Composer`)
- [php](aliases/php.md) - Executes PHP commands. (alias for `Invoke-Php`)
- [php](aliases/php.md) - Executes PHP commands. (alias for `Invoke-Php`)
- [php-server](aliases/php-server.md) - Starts PHP built-in development server. (alias for `Start-PhpServer`)
- [php-server](aliases/php-server.md) - Starts PHP built-in development server. (alias for `Start-PhpServer`)

### 43-laravel (6 aliases)

- [art](aliases/art.md) - Executes Laravel Artisan commands (alias). (alias for `Invoke-LaravelArt`)
- [art](aliases/art.md) - Executes Laravel Artisan commands (alias). (alias for `Invoke-LaravelArt`)
- [artisan](aliases/artisan.md) - Executes Laravel Artisan commands. (alias for `Invoke-LaravelArtisan`)
- [artisan](aliases/artisan.md) - Executes Laravel Artisan commands. (alias for `Invoke-LaravelArtisan`)
- [laravel-new](aliases/laravel-new.md) - Creates a new Laravel application. (alias for `New-LaravelApp`)
- [laravel-new](aliases/laravel-new.md) - Creates a new Laravel application. (alias for `New-LaravelApp`)

### 44-git (3 aliases)

- [Git-CurrentBranch](aliases/Git-CurrentBranch.md) - profile.d/44-git.ps1 (alias for `Get-GitCurrentBranch`)
- [Git-StatusShort](aliases/Git-StatusShort.md) - profile.d/44-git.ps1 (alias for `Get-GitStatusShort`)
- [Prompt-GitSegment](aliases/Prompt-GitSegment.md) - Alias for `Format-PromptGitSegment` (alias for `Format-PromptGitSegment`)

### 45-nextjs (8 aliases)

- [create-next-app](aliases/create-next-app.md) - Creates a new Next.js application. (alias for `New-NextJsApp`)
- [create-next-app](aliases/create-next-app.md) - Creates a new Next.js application. (alias for `New-NextJsApp`)
- [next-build](aliases/next-build.md) - Builds Next.js application for production. (alias for `Build-NextJsApp`)
- [next-build](aliases/next-build.md) - Builds Next.js application for production. (alias for `Build-NextJsApp`)
- [next-dev](aliases/next-dev.md) - Starts Next.js development server. (alias for `Start-NextJsDev`)
- [next-dev](aliases/next-dev.md) - Starts Next.js development server. (alias for `Start-NextJsDev`)
- [next-start](aliases/next-start.md) - Starts Next.js production server. (alias for `Start-NextJsProduction`)
- [next-start](aliases/next-start.md) - Starts Next.js production server. (alias for `Start-NextJsProduction`)

### 46-vite (8 aliases)

- [create-vite](aliases/create-vite.md) - Creates a new Vite project. (alias for `New-ViteProject`)
- [create-vite](aliases/create-vite.md) - Creates a new Vite project. (alias for `New-ViteProject`)
- [vite](aliases/vite.md) - Executes Vite commands. (alias for `Invoke-Vite`)
- [vite](aliases/vite.md) - Executes Vite commands. (alias for `Invoke-Vite`)
- [vite-build](aliases/vite-build.md) - Builds Vite application for production. (alias for `Build-ViteApp`)
- [vite-build](aliases/vite-build.md) - Builds Vite application for production. (alias for `Build-ViteApp`)
- [vite-dev](aliases/vite-dev.md) - Starts Vite development server. (alias for `Start-ViteDev`)
- [vite-dev](aliases/vite-dev.md) - Starts Vite development server. (alias for `Start-ViteDev`)

### 47-angular (6 aliases)

- [ng](aliases/ng.md) - Executes Angular CLI commands. (alias for `Invoke-Angular`)
- [ng](aliases/ng.md) - Executes Angular CLI commands. (alias for `Invoke-Angular`)
- [ng-new](aliases/ng-new.md) - Creates a new Angular application. (alias for `New-AngularApp`)
- [ng-new](aliases/ng-new.md) - Creates a new Angular application. (alias for `New-AngularApp`)
- [ng-serve](aliases/ng-serve.md) - Starts Angular development server. (alias for `Start-AngularDev`)
- [ng-serve](aliases/ng-serve.md) - Starts Angular development server. (alias for `Start-AngularDev`)

### 48-vue (6 aliases)

- [vue](aliases/vue.md) - Executes Vue CLI commands. (alias for `Invoke-Vue`)
- [vue](aliases/vue.md) - Executes Vue CLI commands. (alias for `Invoke-Vue`)
- [vue-create](aliases/vue-create.md) - Creates a new Vue.js project. (alias for `New-VueApp`)
- [vue-create](aliases/vue-create.md) - Creates a new Vue.js project. (alias for `New-VueApp`)
- [vue-serve](aliases/vue-serve.md) - Starts Vue.js development server. (alias for `Start-VueDev`)
- [vue-serve](aliases/vue-serve.md) - Starts Vue.js development server. (alias for `Start-VueDev`)

### 49-nuxt (8 aliases)

- [create-nuxt-app](aliases/create-nuxt-app.md) - Creates a new Nuxt.js application. (alias for `New-NuxtApp`)
- [create-nuxt-app](aliases/create-nuxt-app.md) - Creates a new Nuxt.js application. (alias for `New-NuxtApp`)
- [nuxi](aliases/nuxi.md) - Executes Nuxt CLI (nuxi) commands. (alias for `Invoke-Nuxt`)
- [nuxi](aliases/nuxi.md) - Executes Nuxt CLI (nuxi) commands. (alias for `Invoke-Nuxt`)
- [nuxt-build](aliases/nuxt-build.md) - Builds Nuxt.js application for production. (alias for `Build-NuxtApp`)
- [nuxt-build](aliases/nuxt-build.md) - Builds Nuxt.js application for production. (alias for `Build-NuxtApp`)
- [nuxt-dev](aliases/nuxt-dev.md) - Starts Nuxt.js development server. (alias for `Start-NuxtDev`)
- [nuxt-dev](aliases/nuxt-dev.md) - Starts Nuxt.js development server. (alias for `Start-NuxtDev`)

### 50-azure (8 aliases)

- [az](aliases/az.md) - Executes Azure CLI commands. (alias for `Invoke-Azure`)
- [az](aliases/az.md) - Executes Azure CLI commands. (alias for `Invoke-Azure`)
- [az-login](aliases/az-login.md) - Authenticates with Azure CLI. (alias for `Connect-AzureAccount`)
- [az-login](aliases/az-login.md) - Authenticates with Azure CLI. (alias for `Connect-AzureAccount`)
- [azd](aliases/azd.md) - Executes Azure Developer CLI commands. (alias for `Invoke-AzureDeveloper`)
- [azd](aliases/azd.md) - Executes Azure Developer CLI commands. (alias for `Invoke-AzureDeveloper`)
- [azd-up](aliases/azd-up.md) - Provisions and deploys using Azure Developer CLI. (alias for `Start-AzureDeveloperUp`)
- [azd-up](aliases/azd-up.md) - Provisions and deploys using Azure Developer CLI. (alias for `Start-AzureDeveloperUp`)

### 51-gcloud (8 aliases)

- [gcloud](aliases/gcloud.md) - Executes Google Cloud CLI commands. (alias for `Invoke-GCloud`)
- [gcloud](aliases/gcloud.md) - Executes Google Cloud CLI commands. (alias for `Invoke-GCloud`)
- [gcloud-auth](aliases/gcloud-auth.md) - Manages Google Cloud authentication. (alias for `Set-GCloudAuth`)
- [gcloud-auth](aliases/gcloud-auth.md) - Manages Google Cloud authentication. (alias for `Set-GCloudAuth`)
- [gcloud-config](aliases/gcloud-config.md) - Manages Google Cloud configuration. (alias for `Set-GCloudConfig`)
- [gcloud-config](aliases/gcloud-config.md) - Manages Google Cloud configuration. (alias for `Set-GCloudConfig`)
- [gcloud-projects](aliases/gcloud-projects.md) - Manages Google Cloud Platform projects. (alias for `Get-GCloudProjects`)
- [gcloud-projects](aliases/gcloud-projects.md) - Manages Google Cloud Platform projects. (alias for `Get-GCloudProjects`)

### 52-helm (8 aliases)

- [helm](aliases/helm.md) - Executes Helm commands. (alias for `Invoke-Helm`)
- [helm](aliases/helm.md) - Executes Helm commands. (alias for `Invoke-Helm`)
- [helm-install](aliases/helm-install.md) - Installs Helm charts. (alias for `Install-HelmChart`)
- [helm-install](aliases/helm-install.md) - Installs Helm charts. (alias for `Install-HelmChart`)
- [helm-list](aliases/helm-list.md) - Lists Helm releases. (alias for `Get-HelmReleases`)
- [helm-list](aliases/helm-list.md) - Lists Helm releases. (alias for `Get-HelmReleases`)
- [helm-upgrade](aliases/helm-upgrade.md) - Upgrades Helm releases. (alias for `Update-HelmRelease`)
- [helm-upgrade](aliases/helm-upgrade.md) - Upgrades Helm releases. (alias for `Update-HelmRelease`)

### 53-go (8 aliases)

- [go-build](aliases/go-build.md) - Builds Go programs. (alias for `Build-GoProgram`)
- [go-build](aliases/go-build.md) - Builds Go programs. (alias for `Build-GoProgram`)
- [go-mod](aliases/go-mod.md) - Manages Go modules. (alias for `Invoke-GoModule`)
- [go-mod](aliases/go-mod.md) - Manages Go modules. (alias for `Invoke-GoModule`)
- [go-run](aliases/go-run.md) - Runs Go programs. (alias for `Invoke-GoRun`)
- [go-run](aliases/go-run.md) - Runs Go programs. (alias for `Invoke-GoRun`)
- [go-test](aliases/go-test.md) - Runs Go tests. (alias for `Test-GoPackage`)
- [go-test](aliases/go-test.md) - Runs Go tests. (alias for `Test-GoPackage`)

### 61-eza (11 aliases)

- [l](aliases/l.md) - Lists directory contents using eza (short alias). (alias for `Get-ChildItemEzaShort`)
- [la](aliases/la.md) - Lists all directory contents including hidden files using eza. (alias for `Get-ChildItemEzaAll`)
- [lg](aliases/lg.md) - Lists directory contents with git status using eza. (alias for `Get-ChildItemEzaGit`)
- [ll](aliases/ll.md) - Lists directory contents in long format using eza. (alias for `Get-ChildItemEzaLong`)
- [lla](aliases/lla.md) - Lists all directory contents in long format using eza. (alias for `Get-ChildItemEzaAllLong`)
- [llg](aliases/llg.md) - Lists directory contents in long format with git status using eza. (alias for `Get-ChildItemEzaLongGit`)
- [ls](aliases/ls.md) - Lists directory contents using eza. (alias for `Get-ChildItemEza`)
- [lS](aliases/lS.md) - Lists directory contents sorted by size using eza. (alias for `Get-ChildItemEzaBySize`)
- [lt](aliases/lt.md) - Lists directory contents in tree format using eza. (alias for `Get-ChildItemEzaTree`)
- [lta](aliases/lta.md) - Lists all directory contents in tree format using eza. (alias for `Get-ChildItemEzaTreeAll`)
- [ltime](aliases/ltime.md) - Lists directory contents sorted by modification time using eza. (alias for `Get-ChildItemEzaByTime`)

### 62-navi (4 aliases)

- [cheats](aliases/cheats.md) - Alias for `navi` (alias for `navi`)
- [navib](aliases/navib.md) - Finds the best matching command from navi cheatsheets. (alias for `Invoke-NaviBest`)
- [navip](aliases/navip.md) - Prints commands from navi cheatsheets without executing them. (alias for `Invoke-NaviPrint`)
- [navis](aliases/navis.md) - Searches navi cheatsheets interactively. (alias for `Invoke-NaviSearch`)

### 63-gum (5 aliases)

- [choose](aliases/choose.md) - Shows an interactive selection menu using gum. (alias for `Invoke-GumChoose`)
- [confirm](aliases/confirm.md) - Shows a confirmation prompt using gum. (alias for `Invoke-GumConfirm`)
- [input](aliases/input.md) - Shows an input prompt using gum. (alias for `Invoke-GumInput`)
- [spin](aliases/spin.md) - Shows a spinner while executing a script block using gum. (alias for `Invoke-GumSpin`)
- [style](aliases/style.md) - Styles text output using gum. (alias for `Invoke-GumStyle`)

### 65-procs (2 aliases)

- [ps](aliases/ps.md) - Lists processes with procs. (alias for `procs`)
- [psgrep](aliases/psgrep.md) - Searches processes with procs. (alias for `procs`)

### 66-dust (2 aliases)

- [diskusage](aliases/diskusage.md) - Shows disk usage with dust. (alias for `dust`)
- [du](aliases/du.md) - Shows disk usage with dust. (alias for `dust`)

### 67-uv (4 aliases)

- [pip](aliases/pip.md) - Python package manager using uv instead of pip. (alias for `Invoke-Pip`)
- [uvrun](aliases/uvrun.md) - Runs Python commands in temporary virtual environments using uv. (alias for `Invoke-UVRun`)
- [uvtool](aliases/uvtool.md) - Installs Python tools globally using uv. (alias for `Install-UVTool`)
- [uvvenv](aliases/uvvenv.md) - Creates Python virtual environments using uv. (alias for `New-UVVenv`)

### 68-pixi (3 aliases)

- [pxadd](aliases/pxadd.md) - Installs packages using pixi. (alias for `Invoke-PixiInstall`)
- [pxrun](aliases/pxrun.md) - Runs commands in the pixi environment. (alias for `Invoke-PixiRun`)
- [pxshell](aliases/pxshell.md) - Activates the pixi shell environment. (alias for `Invoke-PixiShell`)

### 69-pnpm (5 aliases)

- [npm](aliases/npm.md) - Alias for `pnpm` (alias for `pnpm`)
- [pnadd](aliases/pnadd.md) - Installs packages using pnpm. (alias for `Invoke-PnpmInstall`)
- [pndev](aliases/pndev.md) - Installs development packages using pnpm. (alias for `Invoke-PnpmDevInstall`)
- [pnrun](aliases/pnrun.md) - Runs npm scripts using pnpm. (alias for `Invoke-PnpmRun`)
- [yarn](aliases/yarn.md) - Alias for `pnpm` (alias for `pnpm`)


## Generation

This documentation was generated from the comment-based help in the profile fragments.
