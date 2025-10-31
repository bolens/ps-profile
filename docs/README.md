# PowerShell Profile API Documentation

This documentation is automatically generated from comment-based help in the profile functions.

**Total Functions:** 153
**Generated:** 2025-10-31 13:00:54

## Functions by Fragment

### 00-bootstrap (4 functions)

- [Set-AgentModeAlias](Set-AgentModeAlias.md) - Creates collision-safe aliases for profile fragments.
- [Set-AgentModeFunction](Set-AgentModeFunction.md) - Creates collision-safe functions for profile fragments.
- [Test-CachedCommand](Test-CachedCommand.md) - Tests for command availability with caching.
- [Test-HasCommand](Test-HasCommand.md) - Tests if a command is available.

### 02-files (23 functions)

- [..](...md) - Changes to the parent directory.
- [...](....md) - Changes to the grandparent directory.
- [....](.....md) - Changes to the great-grandparent directory.
- [bat-cat](bat-cat.md) - Displays file contents with syntax highlighting.
- [csv-to-json](csv-to-json.md) - Converts CSV file to JSON format.
- [desktop](desktop.md) - Changes to the Desktop directory.
- [docs](docs.md) - Changes to the Documents directory.
- [downloads](downloads.md) - Changes to the Downloads directory.
- [Ensure-FileHelper](Ensure-FileHelper.md) - Initializes file helper functions on first use.
- [file-hash](file-hash.md) - Calculates file hash using specified algorithm.
- [filesize](filesize.md) - Shows human-readable file size.
- [from-base64](from-base64.md) - Decodes base64 input to text.
- [head](head.md) - Shows the first N lines of a file.
- [json-pretty](json-pretty.md) - Pretty-prints JSON data.
- [json-to-yaml](json-to-yaml.md) - Converts JSON to YAML format.
- [la](la.md) - Lists all directory contents including hidden files.
- [ll](ll.md) - Lists directory contents with details.
- [lx](lx.md) - Lists directory contents excluding hidden files.
- [tail](tail.md) - Shows the last N lines of a file.
- [to-base64](to-base64.md) - Encodes input to base64 format.
- [tree](tree.md) - Displays directory structure as a tree.
- [xml-to-json](xml-to-json.md) - Converts XML file to JSON format.
- [yaml-to-json](yaml-to-json.md) - Converts YAML to JSON format.

### 05-utilities (19 functions)

- [Add-Path](Add-Path.md) - Adds a directory to the PATH environment variable.
- [backup-profile](backup-profile.md) - Creates a backup of the profile.
- [edit-profile](edit-profile.md) - Opens the profile in VS Code.
- [epoch](epoch.md) - Gets current Unix timestamp.
- [from-epoch](from-epoch.md) - Converts Unix timestamp to DateTime.
- [Get-EnvVar](Get-EnvVar.md) - Gets an environment variable value from the registry.
- [Get-History](Get-History.md) - Shows recent command history.
- [hg](hg.md) - Searches command history.
- [list-functions](list-functions.md) - Lists user-defined functions.
- [myip](myip.md) - Shows public IP address.
- [now](now.md) - Shows current date and time.
- [open-explorer](open-explorer.md) - Opens current directory in File Explorer.
- [Publish-EnvVar](Publish-EnvVar.md) - Broadcasts environment variable changes to all windows.
- [pwgen](pwgen.md) - Generates a random password.
- [reload](reload.md) - Reloads the PowerShell profile.
- [Remove-Path](Remove-Path.md) - Removes a directory from the PATH environment variable.
- [Set-EnvVar](Set-EnvVar.md) - Sets an environment variable value in the registry.
- [speedtest](speedtest.md) - Runs internet speed test.
- [weather](weather.md) - Shows weather information.

### 06-oh-my-posh (2 functions)

- [Initialize-OhMyPosh](Initialize-OhMyPosh.md) - Initializes oh-my-posh prompt framework lazily.
- [prompt](prompt.md) - PowerShell prompt function with lazy oh-my-posh initialization.

### 07-system (20 functions)

- [code](code.md) - Opens files in Visual Studio Code.
- [cp](cp.md) - Copies files and directories.
- [df](df.md) - Shows disk usage information.
- [dns](dns.md) - Resolves DNS names.
- [htop](htop.md) - Shows top CPU-consuming processes.
- [mkdir](mkdir.md) - Creates directories.
- [mv](mv.md) - Moves files and directories.
- [pgrep](pgrep.md) - Searches for patterns in files.
- [ports](ports.md) - Shows network port information.
- [ptest](ptest.md) - Tests network connectivity.
- [rest](rest.md) - Makes REST API calls.
- [rm](rm.md) - Removes files and directories.
- [search](search.md) - Searches for files recursively.
- [touch](touch.md) - Creates empty files.
- [unzip](unzip.md) - Extracts ZIP archives.
- [vi](vi.md) - Opens files in Neovim (vi mode).
- [vim](vim.md) - Opens files in Neovim.
- [web](web.md) - Makes HTTP web requests.
- [which](which.md) - Shows information about commands.
- [zip](zip.md) - Creates ZIP archives.

### 08-system-info (5 functions)

- [battery](battery.md) - Shows battery information.
- [cpuinfo](cpuinfo.md) - Shows CPU information.
- [meminfo](meminfo.md) - Shows memory information.
- [sysinfo](sysinfo.md) - Shows system information.
- [uptime](uptime.md) - Shows system uptime.

### 09-package-managers (21 functions)

- [pna](pna.md) - Adds packages using PNPM.
- [pnb](pnb.md) - Builds the project using PNPM.
- [pnd](pnd.md) - Adds dev dependencies using PNPM.
- [pndev](pndev.md) - Runs development server using PNPM.
- [pni](pni.md) - Installs dependencies using PNPM.
- [pnr](pnr.md) - Runs scripts using PNPM.
- [pns](pns.md) - Starts the project using PNPM.
- [pnt](pnt.md) - Runs tests using PNPM.
- [scleanup](scleanup.md) - Cleans up Scoop cache and old versions.
- [sh](sh.md) - Shows information about Scoop packages.
- [sinstall](sinstall.md) - Installs packages using Scoop.
- [slist](slist.md) - Lists installed Scoop packages.
- [sr](sr.md) - Uninstalls packages using Scoop.
- [ss](ss.md) - Searches for packages in Scoop.
- [su](su.md) - Updates packages using Scoop.
- [suu](suu.md) - Updates all installed Scoop packages.
- [uva](uva.md) - Adds dependencies to UV project.
- [uvi](uvi.md) - Installs Python tools using UV.
- [uvr](uvr.md) - Runs Python commands with UV.
- [uvs](uvs.md) - Syncs UV project dependencies.
- [uvx](uvx.md) - Runs tools installed with UV.

### 10-wsl (3 functions)

- [ubuntu](ubuntu.md) - Launches or switches to Ubuntu WSL distribution.
- [wsl-list](wsl-list.md) - Lists all WSL distributions with their status.
- [wsl-shutdown](wsl-shutdown.md) - Shuts down all WSL distributions.

### 11-git (1 functions)

- [Ensure-GitHelper](Ensure-GitHelper.md) - Ensures Git helper functions are initialized.

### 13-ansible (6 functions)

- [ansible](ansible.md) - Runs Ansible commands via WSL with UTF-8 locale.
- [ansible-doc](ansible-doc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale.
- [ansible-galaxy](ansible-galaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale.
- [ansible-inventory](ansible-inventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale.
- [ansible-playbook](ansible-playbook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale.
- [ansible-vault](ansible-vault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale.

### 15-shortcuts (3 functions)

- [e](e.md) - Opens file in editor quickly.
- [project-root](project-root.md) - Changes to project root directory.
- [vsc](vsc.md) - Opens current directory in VS Code.

### 16-clipboard (2 functions)

- [cb](cb.md) - Copies input to the clipboard.
- [pb](pb.md) - Pastes content from the clipboard.

### 22-containers (9 functions)

- [dcd](dcd.md) - Stops container services using compose (Docker-first).
- [dcl](dcl.md) - Shows container logs using compose (Docker-first).
- [dcu](dcu.md) - Starts container services using compose (Docker-first).
- [dprune](dprune.md) - Prunes unused container system resources (Docker-first).
- [Get-ContainerEngineInfo](Get-ContainerEngineInfo.md) - Gets information about available container engines and compose tools.
- [pcd](pcd.md) - Stops container services using compose (Podman-first).
- [pcl](pcl.md) - Shows container logs using compose (Podman-first).
- [pcu](pcu.md) - Starts container services using compose (Podman-first).
- [pprune](pprune.md) - Prunes unused container system resources (Podman-first).

### 23-starship (1 functions)

- [Initialize-Starship](Initialize-Starship.md) - Initializes the Starship prompt for PowerShell.

### 24-container-utils (2 functions)

- [Set-ContainerEnginePreference](Set-ContainerEnginePreference.md) - Sets the preferred container engine for the session.
- [Test-ContainerEngine](Test-ContainerEngine.md) - Tests for available container engines and compose tools.

### 30-open (1 functions)

- [open](open.md) - Opens files or URLs using the system's default application.

### 33-aliases (1 functions)

- [Enable-Aliases](Enable-Aliases.md) - Enables user-defined aliases and helper functions for enhanced shell experience.

### 59-diagnostics (1 functions)

- [Show-ProfileDiagnostic](Show-ProfileDiagnostic.md) - Shows profile diagnostic information.

### 61-eza (11 functions)

- [l](l.md) - Lists directory contents using eza (short alias).
- [la](la.md) - Lists all directory contents including hidden files using eza.
- [lg](lg.md) - Lists directory contents with git status using eza.
- [ll](ll.md) - Lists directory contents in long format using eza.
- [lla](lla.md) - Lists all directory contents in long format using eza.
- [llg](llg.md) - Lists directory contents in long format with git status using eza.
- [ls](ls.md) - Lists directory contents using eza.
- [lS](lS.md) - Lists directory contents sorted by size using eza.
- [lt](lt.md) - Lists directory contents in tree format using eza.
- [lta](lta.md) - Lists all directory contents in tree format using eza.
- [ltime](ltime.md) - Lists directory contents sorted by modification time using eza.

### 62-navi (3 functions)

- [Invoke-NaviBest](Invoke-NaviBest.md) - Finds the best matching command from navi cheatsheets.
- [Invoke-NaviPrint](Invoke-NaviPrint.md) - Prints commands from navi cheatsheets without executing them.
- [Invoke-NaviSearch](Invoke-NaviSearch.md) - Searches navi cheatsheets interactively.

### 63-gum (5 functions)

- [Invoke-GumChoose](Invoke-GumChoose.md) - Shows an interactive selection menu using gum.
- [Invoke-GumConfirm](Invoke-GumConfirm.md) - Shows a confirmation prompt using gum.
- [Invoke-GumInput](Invoke-GumInput.md) - Shows an input prompt using gum.
- [Invoke-GumSpin](Invoke-GumSpin.md) - Shows a spinner while executing a script block using gum.
- [Invoke-GumStyle](Invoke-GumStyle.md) - Styles text output using gum.

### 67-uv (4 functions)

- [Install-UVTool](Install-UVTool.md) - Installs Python tools globally using uv.
- [Invoke-UVRun](Invoke-UVRun.md) - Runs Python commands in temporary virtual environments using uv.
- [New-UVVenv](New-UVVenv.md) - Creates Python virtual environments using uv.
- [pip](pip.md) - Python package manager using uv instead of pip.

### 68-pixi (3 functions)

- [Invoke-PixiInstall](Invoke-PixiInstall.md) - Installs packages using pixi.
- [Invoke-PixiRun](Invoke-PixiRun.md) - Runs commands in the pixi environment.
- [Invoke-PixiShell](Invoke-PixiShell.md) - Activates the pixi shell environment.

### 69-pnpm (3 functions)

- [Invoke-PnpmDevInstall](Invoke-PnpmDevInstall.md) - Installs development packages using pnpm.
- [Invoke-PnpmInstall](Invoke-PnpmInstall.md) - Installs packages using pnpm.
- [Invoke-PnpmRun](Invoke-PnpmRun.md) - Runs npm scripts using pnpm.

## Generation

This documentation was generated from the comment-based help in the profile fragments.
