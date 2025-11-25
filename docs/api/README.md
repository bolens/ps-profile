# PowerShell Profile API Documentation

This documentation is automatically generated from comment-based help in the profile functions and aliases.

**Total Functions:** 109
**Total Aliases:** 103
**Generated:** 2025-11-25 10:28:36

## Functions by Fragment


### 00-bootstrap (1 functions)

- [Initialize-FragmentWarningSuppression](functions/Initialize-FragmentWarningSuppression.md) - Clears cached missing tool warnings.

### 02-files (7 functions)

- [Ensure-DevTools](functions/Ensure-DevTools.md) - Initializes dev tools utility functions on first use.
- [Ensure-DocumentLatexEngine](functions/Ensure-DocumentLatexEngine.md) - Ensures a LaTeX engine is available for PDF conversions.
- [Ensure-FileConversion-Data](functions/Ensure-FileConversion-Data.md) - Initializes data format conversion utility functions on first use.
- [Ensure-FileConversion-Documents](functions/Ensure-FileConversion-Documents.md) - Initializes document format conversion utility functions on first use.
- [Ensure-FileConversion-Media](functions/Ensure-FileConversion-Media.md) - Initializes media format conversion utility functions on first use.
- [Ensure-FileUtilities](functions/Ensure-FileUtilities.md) - Sets up all file utility functions when any of them is called for the first time.
    This lazy loading approach improves profile startup performance.
    Loads file utility modules from the files-modules subdirectory.
- [Test-DocumentLatexEngineAvailable](functions/Test-DocumentLatexEngineAvailable.md) - Tests whether a supported LaTeX engine is available.

### 06-oh-my-posh (2 functions)

- [Initialize-OhMyPosh](functions/Initialize-OhMyPosh.md) - Initializes oh-my-posh prompt framework lazily.
- [prompt](functions/prompt.md) - PowerShell prompt function with lazy oh-my-posh initialization.

### 07-system (20 functions)

- [Compress-ArchiveCustom](functions/Compress-ArchiveCustom.md) - Creates ZIP archives.
- [Copy-ItemCustom](functions/Copy-ItemCustom.md) - Copies files and directories.
- [Expand-ArchiveCustom](functions/Expand-ArchiveCustom.md) - Extracts ZIP archives.
- [Find-File](functions/Find-File.md) - Searches for files recursively.
- [Find-String](functions/Find-String.md) - Searches for patterns in files.
- [Get-CommandInfo](functions/Get-CommandInfo.md) - Shows information about commands.
- [Get-DiskUsage](functions/Get-DiskUsage.md) - Shows disk usage information.
- [Get-NetworkPorts](functions/Get-NetworkPorts.md) - Shows network port information.
- [Get-TopProcesses](functions/Get-TopProcesses.md) - Shows top CPU-consuming processes.
- [Invoke-RestApi](functions/Invoke-RestApi.md) - Makes REST API calls.
- [Invoke-WebRequestCustom](functions/Invoke-WebRequestCustom.md) - Makes HTTP web requests.
- [Move-ItemCustom](functions/Move-ItemCustom.md) - Moves files and directories.
- [New-Directory](functions/New-Directory.md) - Creates directories.
- [New-EmptyFile](functions/New-EmptyFile.md) - Creates empty files or updates file timestamps.
- [Open-Neovim](functions/Open-Neovim.md) - Opens files in Neovim.
- [Open-NeovimVi](functions/Open-NeovimVi.md) - Opens files in Neovim (vi mode).
- [Open-VSCode](functions/Open-VSCode.md) - Opens files in Visual Studio Code.
- [Remove-ItemCustom](functions/Remove-ItemCustom.md) - Removes files and directories.
- [Resolve-DnsNameCustom](functions/Resolve-DnsNameCustom.md) - Resolves DNS names.
- [Test-NetworkConnection](functions/Test-NetworkConnection.md) - Tests network connectivity.

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

### 23-starship (7 functions)

- [Get-StarshipPromptArguments](functions/Get-StarshipPromptArguments.md) - Builds arguments array for starship prompt command.
- [Initialize-StarshipModule](functions/Initialize-StarshipModule.md) - Ensures Starship module stays loaded to prevent prompt from breaking.
- [Invoke-StarshipInitScript](functions/Invoke-StarshipInitScript.md) - Executes Starship's initialization script and verifies it worked.
- [New-StarshipPromptFunction](functions/New-StarshipPromptFunction.md) - Creates a global prompt function that directly calls starship executable.
- [Test-PromptNeedsReplacement](functions/Test-PromptNeedsReplacement.md) - Checks if a prompt function needs replacement.
- [Test-StarshipInitialized](functions/Test-StarshipInitialized.md) - Tests if Starship is already initialized.
- [Update-VSCodePrompt](functions/Update-VSCodePrompt.md) - Updates VS Code's prompt state if VS Code is active.

### 30-open (1 functions)

- [Open-Item](functions/Open-Item.md) - Opens files or URLs using the system's default application.

### 33-aliases (1 functions)

- [Enable-Aliases](functions/Enable-Aliases.md) - Enables user-defined aliases and helper functions for enhanced shell experience.

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


### 07-system (16 aliases)

- [code](aliases/code.md) - Opens files in Visual Studio Code. (alias for `Open-VSCode`)
- [df](aliases/df.md) - Shows disk usage information. (alias for `Get-DiskUsage`)
- [dns](aliases/dns.md) - Resolves DNS names. (alias for `Resolve-DnsNameCustom`)
- [htop](aliases/htop.md) - Shows top CPU-consuming processes. (alias for `Get-TopProcesses`)
- [pgrep](aliases/pgrep.md) - Searches for patterns in files. (alias for `Find-String`)
- [ports](aliases/ports.md) - Shows network port information. (alias for `Get-NetworkPorts`)
- [ptest](aliases/ptest.md) - Tests network connectivity. (alias for `Test-NetworkConnection`)
- [rest](aliases/rest.md) - Makes REST API calls. (alias for `Invoke-RestApi`)
- [search](aliases/search.md) - Searches for files recursively. (alias for `Find-File`)
- [touch](aliases/touch.md) - Creates empty files or updates file timestamps. (alias for `New-EmptyFile`)
- [unzip](aliases/unzip.md) - Extracts ZIP archives. (alias for `Expand-ArchiveCustom`)
- [vi](aliases/vi.md) - Opens files in Neovim (vi mode). (alias for `Open-NeovimVi`)
- [vim](aliases/vim.md) - Opens files in Neovim. (alias for `Open-Neovim`)
- [web](aliases/web.md) - Makes HTTP web requests. (alias for `Invoke-WebRequestCustom`)
- [which](aliases/which.md) - Shows information about commands. (alias for `Get-CommandInfo`)
- [zip](aliases/zip.md) - Creates ZIP archives. (alias for `Compress-ArchiveCustom`)

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

### 13-ansible (6 aliases)

- [ansible](aliases/ansible.md) - Runs Ansible commands via WSL with UTF-8 locale. (alias for `Invoke-Ansible`)
- [ansible-doc](aliases/ansible-doc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale. (alias for `Get-AnsibleDoc`)
- [ansible-galaxy](aliases/ansible-galaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleGalaxy`)
- [ansible-inventory](aliases/ansible-inventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Get-AnsibleInventory`)
- [ansible-playbook](aliases/ansible-playbook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale. (alias for `Invoke-AnsiblePlaybook`)
- [ansible-vault](aliases/ansible-vault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleVault`)

### 14-ssh (3 aliases)

- [ssh-add-if](aliases/ssh-add-if.md) - Alias for `Add-SSHKeyIfNotLoaded` (alias for `Add-SSHKeyIfNotLoaded`)
- [ssh-agent-start](aliases/ssh-agent-start.md) - Alias for `Start-SSHAgent` (alias for `Start-SSHAgent`)
- [ssh-list](aliases/ssh-list.md) - Alias for `Get-SSHKeys` (alias for `Get-SSHKeys`)

### 15-shortcuts (3 aliases)

- [e](aliases/e.md) - Opens file in the best available editor. (alias for `Open-Editor`)
- [project-root](aliases/project-root.md) - Changes to project root directory. (alias for `Get-ProjectRoot`)
- [vsc](aliases/vsc.md) - Opens files in Visual Studio Code. (alias for `Open-VSCode`)

### 16-clipboard (2 aliases)

- [cb](aliases/cb.md) - Copies input to the clipboard. (alias for `Copy-ToClipboard`)
- [pb](aliases/pb.md) - Pastes content from the clipboard. (alias for `Get-FromClipboard`)

### 19-fzf (2 aliases)

- [fcmd](aliases/fcmd.md) - 17-fzf.ps1 (alias for `Find-CommandFuzzy`)
- [ff](aliases/ff.md) - 17-fzf.ps1 (alias for `Find-FileFuzzy`)

### 30-open (1 aliases)

- [open](aliases/open.md) - Opens files or URLs using the system's default application. (alias for `Open-Item`)

### 33-aliases (2 aliases)

- [la](aliases/la.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhancedAll`)
- [ll](aliases/ll.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhanced`)

### 44-git (3 aliases)

- [Git-CurrentBranch](aliases/Git-CurrentBranch.md) - profile.d/44-git.ps1 (alias for `Get-GitCurrentBranch`)
- [Git-StatusShort](aliases/Git-StatusShort.md) - profile.d/44-git.ps1 (alias for `Get-GitStatusShort`)
- [Prompt-GitSegment](aliases/Prompt-GitSegment.md) - Alias for `Format-PromptGitSegment` (alias for `Format-PromptGitSegment`)

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
