# PowerShell Profile API Documentation

This documentation is automatically generated from comment-based help in the profile functions and aliases.

**Total Functions:** 228
**Total Aliases:** 255
**Generated:** 2025-11-05 13:05:10

## Functions by Fragment

### 00-bootstrap (4 functions)

- [Set-AgentModeAlias](Set-AgentModeAlias.md) - Creates collision-safe aliases for profile fragments.
- [Set-AgentModeFunction](Set-AgentModeFunction.md) - Creates collision-safe functions for profile fragments.
- [Test-CachedCommand](Test-CachedCommand.md) - Tests for command availability with caching.
- [Test-HasCommand](Test-HasCommand.md) - Tests if a command is available.

### 02-files-conversion (22 functions)

- [Convert-Audio](Convert-Audio.md) - Converts audio file formats.
- [Convert-Image](Convert-Image.md) - Converts image file formats.
- [ConvertFrom-Base64](ConvertFrom-Base64.md) - Decodes base64 input to text.
- [ConvertFrom-CsvToJson](ConvertFrom-CsvToJson.md) - Converts CSV file to JSON format.
- [ConvertFrom-CsvToYaml](ConvertFrom-CsvToYaml.md) - Converts CSV file to YAML format.
- [ConvertFrom-DocxToMarkdown](ConvertFrom-DocxToMarkdown.md) - Converts DOCX file to Markdown.
- [ConvertFrom-EpubToMarkdown](ConvertFrom-EpubToMarkdown.md) - Converts EPUB file to Markdown.
- [ConvertFrom-HtmlToMarkdown](ConvertFrom-HtmlToMarkdown.md) - Converts HTML file to Markdown.
- [ConvertFrom-PdfToText](ConvertFrom-PdfToText.md) - Extracts text from PDF file.
- [ConvertFrom-VideoToAudio](ConvertFrom-VideoToAudio.md) - Extracts audio from video file.
- [ConvertFrom-VideoToGif](ConvertFrom-VideoToGif.md) - Converts video to GIF.
- [ConvertFrom-XmlToJson](ConvertFrom-XmlToJson.md) - Converts XML file to JSON format.
- [ConvertFrom-Yaml](ConvertFrom-Yaml.md) - Converts YAML to JSON format.
- [ConvertFrom-YamlToCsv](ConvertFrom-YamlToCsv.md) - Converts YAML file to CSV format.
- [ConvertTo-Base64](ConvertTo-Base64.md) - Encodes input to base64 format.
- [ConvertTo-CsvFromJson](ConvertTo-CsvFromJson.md) - Converts JSON file to CSV format.
- [ConvertTo-HtmlFromMarkdown](ConvertTo-HtmlFromMarkdown.md) - Converts Markdown file to HTML.
- [ConvertTo-Yaml](ConvertTo-Yaml.md) - Converts JSON to YAML format.
- [Ensure-FileConversion](Ensure-FileConversion.md) - Initializes file conversion utility functions on first use.
- [Format-Json](Format-Json.md) - Pretty-prints JSON data.
- [Merge-Pdf](Merge-Pdf.md) - Merges multiple PDF files.
- [Resize-Image](Resize-Image.md) - Resizes an image.

### 02-files-listing (6 functions)

- [Ensure-FileListing](Ensure-FileListing.md) - Initializes file listing utility functions on first use.
- [Get-ChildItemAll](Get-ChildItemAll.md) - Lists all directory contents including hidden files.
- [Get-ChildItemDetailed](Get-ChildItemDetailed.md) - Lists directory contents with details.
- [Get-ChildItemVisible](Get-ChildItemVisible.md) - Lists directory contents excluding hidden files.
- [Get-DirectoryTree](Get-DirectoryTree.md) - Displays directory structure as a tree.
- [Show-FileContent](Show-FileContent.md) - Displays file contents with syntax highlighting.

### 02-files-navigation (7 functions)

- [..](...md) - Changes to the parent directory.
- [...](....md) - Changes to the grandparent directory.
- [....](.....md) - Changes to the great-grandparent directory.
- [Ensure-FileNavigation](Ensure-FileNavigation.md) - Initializes file navigation utility functions on first use.
- [Set-LocationDesktop](Set-LocationDesktop.md) - Changes to the Desktop directory.
- [Set-LocationDocuments](Set-LocationDocuments.md) - Changes to the Documents directory.
- [Set-LocationDownloads](Set-LocationDownloads.md) - Changes to the Downloads directory.

### 02-files-utilities (6 functions)

- [Ensure-FileUtilities](Ensure-FileUtilities.md) - Initializes file utility functions on first use.
- [Get-FileHashValue](Get-FileHashValue.md) - Calculates file hash using specified algorithm.
- [Get-FileHead](Get-FileHead.md) - Shows the first N lines of a file.
- [Get-FileSize](Get-FileSize.md) - Shows human-readable file size.
- [Get-FileTail](Get-FileTail.md) - Shows the last N lines of a file.
- [Get-HexDump](Get-HexDump.md) - Shows hex dump of a file.

### 05-utilities (22 functions)

- [Add-Path](Add-Path.md) - Adds a directory to the PATH environment variable.
- [Backup-Profile](Backup-Profile.md) - Creates a backup of the profile.
- [ConvertFrom-Epoch](ConvertFrom-Epoch.md) - Converts Unix timestamp to DateTime.
- [ConvertFrom-UrlEncoded](ConvertFrom-UrlEncoded.md) - URL-decodes a string.
- [ConvertTo-Epoch](ConvertTo-Epoch.md) - Converts DateTime to Unix timestamp.
- [ConvertTo-UrlEncoded](ConvertTo-UrlEncoded.md) - URL-encodes a string.
- [Edit-Profile](Edit-Profile.md) - Opens the profile in VS Code.
- [Find-History](Find-History.md) - Searches command history.
- [Get-DateTime](Get-DateTime.md) - Shows current date and time.
- [Get-EnvVar](Get-EnvVar.md) - Gets an environment variable value from the registry.
- [Get-Epoch](Get-Epoch.md) - Gets current Unix timestamp.
- [Get-Functions](Get-Functions.md) - Lists user-defined functions.
- [Get-History](Get-History.md) - Shows recent command history.
- [Get-MyIP](Get-MyIP.md) - Shows public IP address.
- [Get-Weather](Get-Weather.md) - Shows weather information.
- [New-RandomPassword](New-RandomPassword.md) - Generates a random password.
- [Open-Explorer](Open-Explorer.md) - Opens current directory in File Explorer.
- [Publish-EnvVar](Publish-EnvVar.md) - Broadcasts environment variable changes to all windows.
- [Reload-Profile](Reload-Profile.md) - Reloads the PowerShell profile.
- [Remove-Path](Remove-Path.md) - Removes a directory from the PATH environment variable.
- [Set-EnvVar](Set-EnvVar.md) - Sets an environment variable value in the registry.
- [Start-SpeedTest](Start-SpeedTest.md) - Runs internet speed test.

### 06-oh-my-posh (2 functions)

- [Initialize-OhMyPosh](Initialize-OhMyPosh.md) - Initializes oh-my-posh prompt framework lazily.
- [prompt](prompt.md) - PowerShell prompt function with lazy oh-my-posh initialization.

### 07-system (20 functions)

- [Compress-ArchiveCustom](Compress-ArchiveCustom.md) - Creates ZIP archives.
- [Copy-ItemCustom](Copy-ItemCustom.md) - Copies files and directories.
- [Expand-ArchiveCustom](Expand-ArchiveCustom.md) - Extracts ZIP archives.
- [Find-File](Find-File.md) - Searches for files recursively.
- [Find-String](Find-String.md) - Searches for patterns in files.
- [Get-CommandInfo](Get-CommandInfo.md) - Shows information about commands.
- [Get-DiskUsage](Get-DiskUsage.md) - Shows disk usage information.
- [Get-NetworkPorts](Get-NetworkPorts.md) - Shows network port information.
- [Get-TopProcesses](Get-TopProcesses.md) - Shows top CPU-consuming processes.
- [Invoke-RestApi](Invoke-RestApi.md) - Makes REST API calls.
- [Invoke-WebRequestCustom](Invoke-WebRequestCustom.md) - Makes HTTP web requests.
- [Move-ItemCustom](Move-ItemCustom.md) - Moves files and directories.
- [New-Directory](New-Directory.md) - Creates directories.
- [New-EmptyFile](New-EmptyFile.md) - Creates empty files.
- [Open-Neovim](Open-Neovim.md) - Opens files in Neovim.
- [Open-NeovimVi](Open-NeovimVi.md) - Opens files in Neovim (vi mode).
- [Open-VSCode](Open-VSCode.md) - Opens files in Visual Studio Code.
- [Remove-ItemCustom](Remove-ItemCustom.md) - Removes files and directories.
- [Resolve-DnsNameCustom](Resolve-DnsNameCustom.md) - Resolves DNS names.
- [Test-NetworkConnection](Test-NetworkConnection.md) - Tests network connectivity.

### 08-system-info (5 functions)

- [Get-BatteryInfo](Get-BatteryInfo.md) - Shows battery information.
- [Get-CpuInfo](Get-CpuInfo.md) - Shows CPU information.
- [Get-MemoryInfo](Get-MemoryInfo.md) - Shows memory information.
- [Get-SystemInfo](Get-SystemInfo.md) - Shows system information.
- [Get-SystemUptime](Get-SystemUptime.md) - Shows system uptime.

### 09-package-managers (21 functions)

- [Add-PnpmDevPackage](Add-PnpmDevPackage.md) - Adds dev dependencies using PNPM.
- [Add-PnpmPackage](Add-PnpmPackage.md) - Adds packages using PNPM.
- [Add-UVDependency](Add-UVDependency.md) - Adds dependencies to UV project.
- [Build-PnpmProject](Build-PnpmProject.md) - Builds the project using PNPM.
- [Clear-ScoopCache](Clear-ScoopCache.md) - Cleans up Scoop cache and old versions.
- [Find-ScoopPackage](Find-ScoopPackage.md) - Searches for packages in Scoop.
- [Get-ScoopPackage](Get-ScoopPackage.md) - Lists installed Scoop packages.
- [Get-ScoopPackageInfo](Get-ScoopPackageInfo.md) - Shows information about Scoop packages.
- [Install-PnpmPackage](Install-PnpmPackage.md) - Installs dependencies using PNPM.
- [Install-ScoopPackage](Install-ScoopPackage.md) - Installs packages using Scoop.
- [Install-UVTool](Install-UVTool.md) - Installs Python tools using UV.
- [Invoke-PnpmScript](Invoke-PnpmScript.md) - Runs scripts using PNPM.
- [Invoke-UVRun](Invoke-UVRun.md) - Runs Python commands with UV.
- [Invoke-UVTool](Invoke-UVTool.md) - Runs tools installed with UV.
- [Start-PnpmDev](Start-PnpmDev.md) - Runs development server using PNPM.
- [Start-PnpmProject](Start-PnpmProject.md) - Starts the project using PNPM.
- [Sync-UVDependencies](Sync-UVDependencies.md) - Syncs UV project dependencies.
- [Test-PnpmProject](Test-PnpmProject.md) - Runs tests using PNPM.
- [Uninstall-ScoopPackage](Uninstall-ScoopPackage.md) - Uninstalls packages using Scoop.
- [Update-ScoopAll](Update-ScoopAll.md) - Updates all installed Scoop packages.
- [Update-ScoopPackage](Update-ScoopPackage.md) - Updates packages using Scoop.

### 10-wsl (3 functions)

- [Get-WSLDistribution](Get-WSLDistribution.md) - Lists all WSL distributions with their status.
- [Start-UbuntuWSL](Start-UbuntuWSL.md) - Launches or switches to Ubuntu WSL distribution.
- [Stop-WSL](Stop-WSL.md) - Shuts down all WSL distributions.

### 11-git (12 functions)

- [Add-GitChanges](Add-GitChanges.md) - Stages changes for commit.
- [Compare-GitChanges](Compare-GitChanges.md) - Shows differences between commits, branches, or working tree.
- [Ensure-GitHelper](Ensure-GitHelper.md) - Ensures Git helper functions are initialized.
- [Get-GitBranch](Get-GitBranch.md) - Lists, creates, or deletes branches.
- [Get-GitChanges](Get-GitChanges.md) - Fetches and merges changes from remote repository.
- [Get-GitLog](Get-GitLog.md) - Shows commit history.
- [Invoke-GitStatus](Invoke-GitStatus.md) - Shows Git repository status.
- [Publish-GitChanges](Publish-GitChanges.md) - Pushes commits to remote repository.
- [Receive-GitChanges](Receive-GitChanges.md) - Downloads objects and refs from remote repository.
- [Save-GitCommit](Save-GitCommit.md) - Commits staged changes.
- [Save-GitCommitWithMessage](Save-GitCommitWithMessage.md) - Commits staged changes with a message.
- [Switch-GitBranch](Switch-GitBranch.md) - Switches branches or restores working tree files.

### 13-ansible (6 functions)

- [Get-AnsibleDoc](Get-AnsibleDoc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale.
- [Get-AnsibleInventory](Get-AnsibleInventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale.
- [Invoke-Ansible](Invoke-Ansible.md) - Runs Ansible commands via WSL with UTF-8 locale.
- [Invoke-AnsibleGalaxy](Invoke-AnsibleGalaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale.
- [Invoke-AnsiblePlaybook](Invoke-AnsiblePlaybook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale.
- [Invoke-AnsibleVault](Invoke-AnsibleVault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale.

### 15-shortcuts (3 functions)

- [Get-ProjectRoot](Get-ProjectRoot.md) - Changes to project root directory.
- [Open-Editor](Open-Editor.md) - Opens file in editor quickly.
- [Open-VSCode](Open-VSCode.md) - Opens current directory in VS Code.

### 16-clipboard (2 functions)

- [Copy-ToClipboard](Copy-ToClipboard.md) - Copies input to the clipboard.
- [Get-FromClipboard](Get-FromClipboard.md) - Pastes content from the clipboard.

### 22-containers (9 functions)

- [Clear-ContainerSystem](Clear-ContainerSystem.md) - Prunes unused container system resources (Docker-first).
- [Clear-ContainerSystemPodman](Clear-ContainerSystemPodman.md) - Prunes unused container system resources (Podman-first).
- [Get-ContainerComposeLogs](Get-ContainerComposeLogs.md) - Shows container logs using compose (Docker-first).
- [Get-ContainerComposeLogsPodman](Get-ContainerComposeLogsPodman.md) - Shows container logs using compose (Podman-first).
- [Get-ContainerEngineInfo](Get-ContainerEngineInfo.md) - Gets information about available container engines and compose tools.
- [Start-ContainerCompose](Start-ContainerCompose.md) - Starts container services using compose (Docker-first).
- [Start-ContainerComposePodman](Start-ContainerComposePodman.md) - Starts container services using compose (Podman-first).
- [Stop-ContainerCompose](Stop-ContainerCompose.md) - Stops container services using compose (Docker-first).
- [Stop-ContainerComposePodman](Stop-ContainerComposePodman.md) - Stops container services using compose (Podman-first).

### 23-starship (2 functions)

- [Initialize-SmartPrompt](Initialize-SmartPrompt.md) - Initializes a smart fallback prompt when Starship is not available.
- [Initialize-Starship](Initialize-Starship.md) - Initializes the Starship prompt for PowerShell.

### 24-container-utils (2 functions)

- [Set-ContainerEnginePreference](Set-ContainerEnginePreference.md) - Sets the preferred container engine for the session.
- [Test-ContainerEngine](Test-ContainerEngine.md) - Tests for available container engines and compose tools.

### 30-open (1 functions)

- [Open-Item](Open-Item.md) - Opens files or URLs using the system's default application.

### 33-aliases (1 functions)

- [Enable-Aliases](Enable-Aliases.md) - Enables user-defined aliases and helper functions for enhanced shell experience.

### 59-diagnostics (4 functions)

- [Show-CommandUsageStats](Show-CommandUsageStats.md) - Shows command usage statistics for optimization insights.
- [Show-ProfileDiagnostic](Show-ProfileDiagnostic.md) - Shows profile diagnostic information.
- [Show-ProfileStartupTime](Show-ProfileStartupTime.md) - Shows profile startup time information.
- [Test-ProfileHealth](Test-ProfileHealth.md) - Performs basic health checks for critical dependencies.

### 61-eza (11 functions)

- [Get-ChildItemEza](Get-ChildItemEza.md) - Lists directory contents using eza.
- [Get-ChildItemEzaAll](Get-ChildItemEzaAll.md) - Lists all directory contents including hidden files using eza.
- [Get-ChildItemEzaAllLong](Get-ChildItemEzaAllLong.md) - Lists all directory contents in long format using eza.
- [Get-ChildItemEzaBySize](Get-ChildItemEzaBySize.md) - Lists directory contents sorted by size using eza.
- [Get-ChildItemEzaByTime](Get-ChildItemEzaByTime.md) - Lists directory contents sorted by modification time using eza.
- [Get-ChildItemEzaGit](Get-ChildItemEzaGit.md) - Lists directory contents with git status using eza.
- [Get-ChildItemEzaLong](Get-ChildItemEzaLong.md) - Lists directory contents in long format using eza.
- [Get-ChildItemEzaLongGit](Get-ChildItemEzaLongGit.md) - Lists directory contents in long format with git status using eza.
- [Get-ChildItemEzaShort](Get-ChildItemEzaShort.md) - Lists directory contents using eza (short alias).
- [Get-ChildItemEzaTree](Get-ChildItemEzaTree.md) - Lists directory contents in tree format using eza.
- [Get-ChildItemEzaTreeAll](Get-ChildItemEzaTreeAll.md) - Lists all directory contents in tree format using eza.

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
- [Invoke-Pip](Invoke-Pip.md) - Python package manager using uv instead of pip.
- [Invoke-UVRun](Invoke-UVRun.md) - Runs Python commands in temporary virtual environments using uv.
- [New-UVVenv](New-UVVenv.md) - Creates Python virtual environments using uv.

### 68-pixi (3 functions)

- [Invoke-PixiInstall](Invoke-PixiInstall.md) - Installs packages using pixi.
- [Invoke-PixiRun](Invoke-PixiRun.md) - Runs commands in the pixi environment.
- [Invoke-PixiShell](Invoke-PixiShell.md) - Activates the pixi shell environment.

### 69-pnpm (3 functions)

- [Invoke-PnpmDevInstall](Invoke-PnpmDevInstall.md) - Installs development packages using pnpm.
- [Invoke-PnpmInstall](Invoke-PnpmInstall.md) - Installs packages using pnpm.
- [Invoke-PnpmRun](Invoke-PnpmRun.md) - Runs npm scripts using pnpm.

### 70-profile-updates (1 functions)

- [Test-ProfileUpdates](Test-ProfileUpdates.md) - Checks for profile updates and displays changelog.

### 71-network-utils (4 functions)

- [Invoke-HttpRequestWithRetry](Invoke-HttpRequestWithRetry.md) - Makes HTTP requests with retry logic and timeout handling.
- [Invoke-WithRetry](Invoke-WithRetry.md) - Executes a network operation with retry logic and timeout handling.
- [Resolve-HostWithRetry](Resolve-HostWithRetry.md) - Resolves hostnames with retry logic.
- [Test-NetworkConnectivity](Test-NetworkConnectivity.md) - Tests network connectivity with retry logic.

### 72-error-handling (3 functions)

- [Invoke-ProfileErrorHandler](Invoke-ProfileErrorHandler.md) - Enhanced global error handler with recovery suggestions.
- [Invoke-SafeFragmentLoad](Invoke-SafeFragmentLoad.md) - Loads profile fragments with enhanced error handling and retry logic.
- [Write-ProfileError](Write-ProfileError.md) - Logs errors with enhanced context and formatting.

### 73-performance-insights (5 functions)

- [Clear-PerformanceData](Clear-PerformanceData.md) - Clears all collected performance data.
- [Show-PerformanceInsights](Show-PerformanceInsights.md) - Shows performance insights for command execution.
- [Start-CommandTimer](Start-CommandTimer.md) - Tracks command execution performance and provides insights.
- [Stop-CommandTimer](Stop-CommandTimer.md) - Stops command timing and records the duration.
- [Test-PerformanceHealth](Test-PerformanceHealth.md) - Performs a quick performance check of the current session.

### 74-enhanced-history (9 functions)

- [Find-HistoryFuzzy](Find-HistoryFuzzy.md) - Performs fuzzy search on command history.
- [Find-HistoryQuick](Find-HistoryQuick.md) - Quick search in command history.
- [Invoke-LastCommand](Invoke-LastCommand.md) - Shows the last command matching a pattern.
- [r](r.md) - Executes a command from recent history by number or pattern.
- [Remove-HistoryDuplicates](Remove-HistoryDuplicates.md) - Removes duplicate commands from history.
- [Remove-OldHistory](Remove-OldHistory.md) - Removes old commands from history.
- [Search-HistoryInteractive](Search-HistoryInteractive.md) - Interactive history search with preview.
- [Show-HistoryStats](Show-HistoryStats.md) - Shows statistics about command history usage.
- [Show-RecentCommands](Show-RecentCommands.md) - Shows recent commands with quick selection.

### 75-system-monitor (6 functions)

- [Show-CPUInfo](Show-CPUInfo.md) - Shows detailed CPU information and usage.
- [Show-DiskInfo](Show-DiskInfo.md) - Shows detailed disk usage information.
- [Show-MemoryInfo](Show-MemoryInfo.md) - Shows detailed memory usage information.
- [Show-NetworkInfo](Show-NetworkInfo.md) - Shows detailed network information.
- [Show-SystemDashboard](Show-SystemDashboard.md) - Shows a comprehensive system status dashboard.
- [Show-SystemStatus](Show-SystemStatus.md) - Shows a compact system status overview.

### 76-smart-navigation (11 functions)

- [Add-DirectoryBookmark](Add-DirectoryBookmark.md) - Creates a directory bookmark.
- [Get-DirectoryBookmark](Get-DirectoryBookmark.md) - Jumps to a bookmarked directory.
- [Jump-Directory](Jump-Directory.md) - Jumps to frequently used directories.
- [Jump-DirectoryQuick](Jump-DirectoryQuick.md) - Quick directory jumping alias.
- [Remove-DirectoryBookmark](Remove-DirectoryBookmark.md) - Removes a directory bookmark.
- [Set-LocationBack](Set-LocationBack.md) - Goes back to the previous directory.
- [Set-LocationForward](Set-LocationForward.md) - Goes forward in the navigation history.
- [Set-LocationTracked](Set-LocationTracked.md) - Enhanced change directory with navigation tracking.
- [Show-DirectoryBookmarks](Show-DirectoryBookmarks.md) - Lists all directory bookmarks.
- [Show-FrequentDirectories](Show-FrequentDirectories.md) - Lists frequently used directories.
- [Update-DirectoryStats](Update-DirectoryStats.md) - Tracks directory navigation for smart jumping.

## Aliases by Fragment

### 02-files-conversion (42 aliases)

- [audio-convert](audio-convert.md) - Converts audio file formats. (alias for `Convert-Audio`)
- [audio-convert](audio-convert.md) - Converts audio file formats. (alias for `Convert-Audio`)
- [csv-to-json](csv-to-json.md) - Converts CSV file to JSON format. (alias for `ConvertFrom-CsvToJson`)
- [csv-to-json](csv-to-json.md) - Converts CSV file to JSON format. (alias for `ConvertFrom-CsvToJson`)
- [csv-to-yaml](csv-to-yaml.md) - Converts CSV file to YAML format. (alias for `ConvertFrom-CsvToYaml`)
- [csv-to-yaml](csv-to-yaml.md) - Converts CSV file to YAML format. (alias for `ConvertFrom-CsvToYaml`)
- [docx-to-markdown](docx-to-markdown.md) - Converts DOCX file to Markdown. (alias for `ConvertFrom-DocxToMarkdown`)
- [docx-to-markdown](docx-to-markdown.md) - Converts DOCX file to Markdown. (alias for `ConvertFrom-DocxToMarkdown`)
- [epub-to-markdown](epub-to-markdown.md) - Converts EPUB file to Markdown. (alias for `ConvertFrom-EpubToMarkdown`)
- [epub-to-markdown](epub-to-markdown.md) - Converts EPUB file to Markdown. (alias for `ConvertFrom-EpubToMarkdown`)
- [from-base64](from-base64.md) - Decodes base64 input to text. (alias for `ConvertFrom-Base64`)
- [from-base64](from-base64.md) - Decodes base64 input to text. (alias for `ConvertFrom-Base64`)
- [html-to-markdown](html-to-markdown.md) - Converts HTML file to Markdown. (alias for `ConvertFrom-HtmlToMarkdown`)
- [html-to-markdown](html-to-markdown.md) - Converts HTML file to Markdown. (alias for `ConvertFrom-HtmlToMarkdown`)
- [image-convert](image-convert.md) - Converts image file formats. (alias for `Convert-Image`)
- [image-convert](image-convert.md) - Converts image file formats. (alias for `Convert-Image`)
- [image-resize](image-resize.md) - Resizes an image. (alias for `Resize-Image`)
- [image-resize](image-resize.md) - Resizes an image. (alias for `Resize-Image`)
- [json-pretty](json-pretty.md) - Pretty-prints JSON data. (alias for `Format-Json`)
- [json-pretty](json-pretty.md) - Initializes file conversion utility functions on first use. (alias for `Format-Json`)
- [json-to-csv](json-to-csv.md) - Converts JSON file to CSV format. (alias for `ConvertTo-CsvFromJson`)
- [json-to-csv](json-to-csv.md) - Converts JSON file to CSV format. (alias for `ConvertTo-CsvFromJson`)
- [json-to-yaml](json-to-yaml.md) - Converts JSON to YAML format. (alias for `ConvertTo-Yaml`)
- [json-to-yaml](json-to-yaml.md) - Converts JSON to YAML format. (alias for `ConvertTo-Yaml`)
- [markdown-to-html](markdown-to-html.md) - Converts Markdown file to HTML. (alias for `ConvertTo-HtmlFromMarkdown`)
- [markdown-to-html](markdown-to-html.md) - Converts Markdown file to HTML. (alias for `ConvertTo-HtmlFromMarkdown`)
- [pdf-merge](pdf-merge.md) - Merges multiple PDF files. (alias for `Merge-Pdf`)
- [pdf-merge](pdf-merge.md) - Merges multiple PDF files. (alias for `Merge-Pdf`)
- [pdf-to-text](pdf-to-text.md) - Extracts text from PDF file. (alias for `ConvertFrom-PdfToText`)
- [pdf-to-text](pdf-to-text.md) - Extracts text from PDF file. (alias for `ConvertFrom-PdfToText`)
- [to-base64](to-base64.md) - Encodes input to base64 format. (alias for `ConvertTo-Base64`)
- [to-base64](to-base64.md) - Encodes input to base64 format. (alias for `ConvertTo-Base64`)
- [video-to-audio](video-to-audio.md) - Extracts audio from video file. (alias for `ConvertFrom-VideoToAudio`)
- [video-to-audio](video-to-audio.md) - Extracts audio from video file. (alias for `ConvertFrom-VideoToAudio`)
- [video-to-gif](video-to-gif.md) - Converts video to GIF. (alias for `ConvertFrom-VideoToGif`)
- [video-to-gif](video-to-gif.md) - Converts video to GIF. (alias for `ConvertFrom-VideoToGif`)
- [xml-to-json](xml-to-json.md) - Converts XML file to JSON format. (alias for `ConvertFrom-XmlToJson`)
- [xml-to-json](xml-to-json.md) - Converts XML file to JSON format. (alias for `ConvertFrom-XmlToJson`)
- [yaml-to-csv](yaml-to-csv.md) - Converts YAML file to CSV format. (alias for `ConvertFrom-YamlToCsv`)
- [yaml-to-csv](yaml-to-csv.md) - Converts YAML file to CSV format. (alias for `ConvertFrom-YamlToCsv`)
- [yaml-to-json](yaml-to-json.md) - Converts YAML to JSON format. (alias for `ConvertFrom-Yaml`)
- [yaml-to-json](yaml-to-json.md) - Converts YAML to JSON format. (alias for `ConvertFrom-Yaml`)

### 02-files-listing (10 aliases)

- [bat-cat](bat-cat.md) - Initializes file listing utility functions on first use. (alias for `Show-FileContent`)
- [bat-cat](bat-cat.md) - Displays file contents with syntax highlighting. (alias for `Show-FileContent`)
- [la](la.md) - Initializes file listing utility functions on first use. (alias for `Get-ChildItemAll`)
- [la](la.md) - Lists all directory contents including hidden files. (alias for `Get-ChildItemAll`)
- [ll](ll.md) - Initializes file listing utility functions on first use. (alias for `Get-ChildItemDetailed`)
- [ll](ll.md) - Lists directory contents with details. (alias for `Get-ChildItemDetailed`)
- [lx](lx.md) - Initializes file listing utility functions on first use. (alias for `Get-ChildItemVisible`)
- [lx](lx.md) - Lists directory contents excluding hidden files. (alias for `Get-ChildItemVisible`)
- [tree](tree.md) - Initializes file listing utility functions on first use. (alias for `Get-DirectoryTree`)
- [tree](tree.md) - Displays directory structure as a tree. (alias for `Get-DirectoryTree`)

### 02-files-navigation (6 aliases)

- [desktop](desktop.md) - Initializes file navigation utility functions on first use. (alias for `Set-LocationDesktop`)
- [desktop](desktop.md) - Changes to the Desktop directory. (alias for `Set-LocationDesktop`)
- [docs](docs.md) - Initializes file navigation utility functions on first use. (alias for `Set-LocationDocuments`)
- [docs](docs.md) - Changes to the Documents directory. (alias for `Set-LocationDocuments`)
- [downloads](downloads.md) - Initializes file navigation utility functions on first use. (alias for `Set-LocationDownloads`)
- [downloads](downloads.md) - Changes to the Downloads directory. (alias for `Set-LocationDownloads`)

### 02-files-utilities (10 aliases)

- [file-hash](file-hash.md) - Calculates file hash using specified algorithm. (alias for `Get-FileHashValue`)
- [file-hash](file-hash.md) - Calculates file hash using specified algorithm. (alias for `Get-FileHashValue`)
- [filesize](filesize.md) - Shows human-readable file size. (alias for `Get-FileSize`)
- [filesize](filesize.md) - Shows human-readable file size. (alias for `Get-FileSize`)
- [head](head.md) - Initializes file utility functions on first use. (alias for `Get-FileHead`)
- [head](head.md) - Shows the first N lines of a file. (alias for `Get-FileHead`)
- [hex-dump](hex-dump.md) - Shows hex dump of a file. (alias for `Get-HexDump`)
- [hex-dump](hex-dump.md) - Shows hex dump of a file. (alias for `Get-HexDump`)
- [tail](tail.md) - Initializes file utility functions on first use. (alias for `Get-FileTail`)
- [tail](tail.md) - Shows the last N lines of a file. (alias for `Get-FileTail`)

### 05-utilities (16 aliases)

- [backup-profile](backup-profile.md) - Creates a backup of the profile. (alias for `Backup-Profile`)
- [edit-profile](edit-profile.md) - Opens the profile in VS Code. (alias for `Edit-Profile`)
- [epoch](epoch.md) - Gets current Unix timestamp. (alias for `Get-Epoch`)
- [from-epoch](from-epoch.md) - Converts Unix timestamp to DateTime. (alias for `ConvertFrom-Epoch`)
- [hg](hg.md) - Searches command history. (alias for `Find-History`)
- [list-functions](list-functions.md) - Lists user-defined functions. (alias for `Get-Functions`)
- [myip](myip.md) - Shows public IP address. (alias for `Get-MyIP`)
- [now](now.md) - Shows current date and time. (alias for `Get-DateTime`)
- [open-explorer](open-explorer.md) - Opens current directory in File Explorer. (alias for `Open-Explorer`)
- [pwgen](pwgen.md) - Generates a random password. (alias for `New-RandomPassword`)
- [reload](reload.md) - Reloads the PowerShell profile. (alias for `Reload-Profile`)
- [speedtest](speedtest.md) - Runs internet speed test. (alias for `Start-SpeedTest`)
- [to-epoch](to-epoch.md) - Converts DateTime to Unix timestamp. (alias for `ConvertTo-Epoch`)
- [url-decode](url-decode.md) - URL-decodes a string. (alias for `ConvertFrom-UrlEncoded`)
- [url-encode](url-encode.md) - URL-encodes a string. (alias for `ConvertTo-UrlEncoded`)
- [weather](weather.md) - Shows weather information. (alias for `Get-Weather`)

### 07-system (16 aliases)

- [code](code.md) - Opens files in Visual Studio Code. (alias for `Open-VSCode`)
- [df](df.md) - Shows disk usage information. (alias for `Get-DiskUsage`)
- [dns](dns.md) - Resolves DNS names. (alias for `Resolve-DnsNameCustom`)
- [htop](htop.md) - Shows top CPU-consuming processes. (alias for `Get-TopProcesses`)
- [pgrep](pgrep.md) - Searches for patterns in files. (alias for `Find-String`)
- [ports](ports.md) - Shows network port information. (alias for `Get-NetworkPorts`)
- [ptest](ptest.md) - Tests network connectivity. (alias for `Test-NetworkConnection`)
- [rest](rest.md) - Makes REST API calls. (alias for `Invoke-RestApi`)
- [search](search.md) - Searches for files recursively. (alias for `Find-File`)
- [touch](touch.md) - Creates empty files. (alias for `New-EmptyFile`)
- [unzip](unzip.md) - Extracts ZIP archives. (alias for `Expand-ArchiveCustom`)
- [vi](vi.md) - Opens files in Neovim (vi mode). (alias for `Open-NeovimVi`)
- [vim](vim.md) - Opens files in Neovim. (alias for `Open-Neovim`)
- [web](web.md) - Makes HTTP web requests. (alias for `Invoke-WebRequestCustom`)
- [which](which.md) - Shows information about commands. (alias for `Get-CommandInfo`)
- [zip](zip.md) - Creates ZIP archives. (alias for `Compress-ArchiveCustom`)

### 08-system-info (5 aliases)

- [battery](battery.md) - Shows battery information. (alias for `Get-BatteryInfo`)
- [cpuinfo](cpuinfo.md) - Shows CPU information. (alias for `Get-CpuInfo`)
- [meminfo](meminfo.md) - Shows memory information. (alias for `Get-MemoryInfo`)
- [sysinfo](sysinfo.md) - Shows system information. (alias for `Get-SystemInfo`)
- [uptime](uptime.md) - Shows system uptime. (alias for `Get-SystemUptime`)

### 09-package-managers (21 aliases)

- [pna](pna.md) - Adds packages using PNPM. (alias for `Add-PnpmPackage`)
- [pnb](pnb.md) - Builds the project using PNPM. (alias for `Build-PnpmProject`)
- [pnd](pnd.md) - Adds dev dependencies using PNPM. (alias for `Add-PnpmDevPackage`)
- [pndev](pndev.md) - Runs development server using PNPM. (alias for `Start-PnpmDev`)
- [pni](pni.md) - Installs dependencies using PNPM. (alias for `Install-PnpmPackage`)
- [pnr](pnr.md) - Runs scripts using PNPM. (alias for `Invoke-PnpmScript`)
- [pns](pns.md) - Starts the project using PNPM. (alias for `Start-PnpmProject`)
- [pnt](pnt.md) - Runs tests using PNPM. (alias for `Test-PnpmProject`)
- [scleanup](scleanup.md) - Cleans up Scoop cache and old versions. (alias for `Clear-ScoopCache`)
- [sh](sh.md) - Shows information about Scoop packages. (alias for `Get-ScoopPackageInfo`)
- [sinstall](sinstall.md) - Installs packages using Scoop. (alias for `Install-ScoopPackage`)
- [slist](slist.md) - Lists installed Scoop packages. (alias for `Get-ScoopPackage`)
- [sr](sr.md) - Uninstalls packages using Scoop. (alias for `Uninstall-ScoopPackage`)
- [ss](ss.md) - Searches for packages in Scoop. (alias for `Find-ScoopPackage`)
- [su](su.md) - Updates packages using Scoop. (alias for `Update-ScoopPackage`)
- [suu](suu.md) - Updates all installed Scoop packages. (alias for `Update-ScoopAll`)
- [uva](uva.md) - Adds dependencies to UV project. (alias for `Add-UVDependency`)
- [uvi](uvi.md) - Installs Python tools using UV. (alias for `Install-UVTool`)
- [uvr](uvr.md) - Runs Python commands with UV. (alias for `Invoke-UVRun`)
- [uvs](uvs.md) - Syncs UV project dependencies. (alias for `Sync-UVDependencies`)
- [uvx](uvx.md) - Runs tools installed with UV. (alias for `Invoke-UVTool`)

### 10-wsl (3 aliases)

- [ubuntu](ubuntu.md) - Launches or switches to Ubuntu WSL distribution. (alias for `Start-UbuntuWSL`)
- [wsl-list](wsl-list.md) - Lists all WSL distributions with their status. (alias for `Get-WSLDistribution`)
- [wsl-shutdown](wsl-shutdown.md) - Shuts down all WSL distributions. (alias for `Stop-WSL`)

### 11-git (41 aliases)

- [cdg](cdg.md) - Ensures Git helper functions are initialized. (alias for `Set-LocationGitRoot`)
- [cdg](cdg.md) - Alias for `Set-LocationGitRoot` (alias for `Set-LocationGitRoot`)
- [ga](ga.md) - Stages changes for commit. (alias for `Add-GitChanges`)
- [gb](gb.md) - Lists, creates, or deletes branches. (alias for `Get-GitBranch`)
- [gc](gc.md) - Commits staged changes. (alias for `Save-GitCommit`)
- [gcl](gcl.md) - Alias for `Invoke-GitClone` (alias for `Invoke-GitClone`)
- [gcl](gcl.md) - Ensures Git helper functions are initialized. (alias for `Invoke-GitClone`)
- [gclean](gclean.md) - Ensures Git helper functions are initialized. (alias for `Clear-GitUntracked`)
- [gclean](gclean.md) - Alias for `Clear-GitUntracked` (alias for `Clear-GitUntracked`)
- [gcm](gcm.md) - Commits staged changes with a message. (alias for `Save-GitCommitWithMessage`)
- [gco](gco.md) - Switches branches or restores working tree files. (alias for `Switch-GitBranch`)
- [gd](gd.md) - Shows differences between commits, branches, or working tree. (alias for `Compare-GitChanges`)
- [gdefault](gdefault.md) - Alias for `Get-GitDefaultBranch` (alias for `Get-GitDefaultBranch`)
- [gdefault](gdefault.md) - Alias for `Get-GitDefaultBranch` (alias for `Get-GitDefaultBranch`)
- [gf](gf.md) - Downloads objects and refs from remote repository. (alias for `Receive-GitChanges`)
- [gl](gl.md) - Shows commit history. (alias for `Get-GitLog`)
- [gob](gob.md) - Alias for `Switch-GitPreviousBranch` (alias for `Switch-GitPreviousBranch`)
- [gob](gob.md) - Alias for `Switch-GitPreviousBranch` (alias for `Switch-GitPreviousBranch`)
- [gp](gp.md) - Pushes commits to remote repository. (alias for `Publish-GitChanges`)
- [gpl](gpl.md) - Fetches and merges changes from remote repository. (alias for `Get-GitChanges`)
- [gprune](gprune.md) - Alias for `Remove-GitMergedBranches` (alias for `Remove-GitMergedBranches`)
- [gprune](gprune.md) - Alias for `Remove-GitMergedBranches` (alias for `Remove-GitMergedBranches`)
- [gr](gr.md) - Alias for `Merge-GitRebase` (alias for `Merge-GitRebase`)
- [gr](gr.md) - Ensures Git helper functions are initialized. (alias for `Merge-GitRebase`)
- [grc](grc.md) - Ensures Git helper functions are initialized. (alias for `Continue-GitRebase`)
- [grc](grc.md) - Alias for `Continue-GitRebase` (alias for `Continue-GitRebase`)
- [gs](gs.md) - Shows Git repository status. (alias for `Invoke-GitStatus`)
- [gsta](gsta.md) - Alias for `Save-GitStash` (alias for `Save-GitStash`)
- [gsta](gsta.md) - Ensures Git helper functions are initialized. (alias for `Save-GitStash`)
- [gstp](gstp.md) - Alias for `Restore-GitStash` (alias for `Restore-GitStash`)
- [gstp](gstp.md) - Ensures Git helper functions are initialized. (alias for `Restore-GitStash`)
- [gsub](gsub.md) - Ensures Git helper functions are initialized. (alias for `Update-GitSubmodule`)
- [gsub](gsub.md) - Alias for `Update-GitSubmodule` (alias for `Update-GitSubmodule`)
- [gsync](gsync.md) - Alias for `Sync-GitRepository` (alias for `Sync-GitRepository`)
- [gsync](gsync.md) - Alias for `Sync-GitRepository` (alias for `Sync-GitRepository`)
- [gundo](gundo.md) - Alias for `Undo-GitCommit` (alias for `Undo-GitCommit`)
- [gundo](gundo.md) - Alias for `Undo-GitCommit` (alias for `Undo-GitCommit`)
- [prc](prc.md) - Alias for `New-GitHubPullRequest` (alias for `New-GitHubPullRequest`)
- [prc](prc.md) - Alias for `New-GitHubPullRequest` (alias for `New-GitHubPullRequest`)
- [prv](prv.md) - Alias for `Show-GitHubPullRequest` (alias for `Show-GitHubPullRequest`)
- [prv](prv.md) - Alias for `Show-GitHubPullRequest` (alias for `Show-GitHubPullRequest`)

### 13-ansible (6 aliases)

- [ansible](ansible.md) - Runs Ansible commands via WSL with UTF-8 locale. (alias for `Invoke-Ansible`)
- [ansible-doc](ansible-doc.md) - Runs Ansible documentation commands via WSL with UTF-8 locale. (alias for `Get-AnsibleDoc`)
- [ansible-galaxy](ansible-galaxy.md) - Runs Ansible Galaxy commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleGalaxy`)
- [ansible-inventory](ansible-inventory.md) - Runs Ansible inventory commands via WSL with UTF-8 locale. (alias for `Get-AnsibleInventory`)
- [ansible-playbook](ansible-playbook.md) - Runs Ansible playbook commands via WSL with UTF-8 locale. (alias for `Invoke-AnsiblePlaybook`)
- [ansible-vault](ansible-vault.md) - Runs Ansible Vault commands via WSL with UTF-8 locale. (alias for `Invoke-AnsibleVault`)

### 14-ssh (3 aliases)

- [ssh-add-if](ssh-add-if.md) - Alias for `Add-SSHKeyIfNotLoaded` (alias for `Add-SSHKeyIfNotLoaded`)
- [ssh-agent-start](ssh-agent-start.md) - Alias for `Start-SSHAgent` (alias for `Start-SSHAgent`)
- [ssh-list](ssh-list.md) - Alias for `Get-SSHKeys` (alias for `Get-SSHKeys`)

### 15-shortcuts (3 aliases)

- [e](e.md) - Opens file in editor quickly. (alias for `Open-Editor`)
- [project-root](project-root.md) - Changes to project root directory. (alias for `Get-ProjectRoot`)
- [vsc](vsc.md) - Opens current directory in VS Code. (alias for `Open-VSCode`)

### 16-clipboard (2 aliases)

- [cb](cb.md) - Copies input to the clipboard. (alias for `Copy-ToClipboard`)
- [pb](pb.md) - Pastes content from the clipboard. (alias for `Get-FromClipboard`)

### 19-fzf (2 aliases)

- [fcmd](fcmd.md) - 17-fzf.ps1 (alias for `Find-CommandFuzzy`)
- [ff](ff.md) - 17-fzf.ps1 (alias for `Find-FileFuzzy`)

### 22-containers (8 aliases)

- [dcd](dcd.md) - Stops container services using compose (Docker-first). (alias for `Stop-ContainerCompose`)
- [dcl](dcl.md) - Shows container logs using compose (Docker-first). (alias for `Get-ContainerComposeLogs`)
- [dcu](dcu.md) - Starts container services using compose (Docker-first). (alias for `Start-ContainerCompose`)
- [dprune](dprune.md) - Prunes unused container system resources (Docker-first). (alias for `Clear-ContainerSystem`)
- [pcd](pcd.md) - Stops container services using compose (Podman-first). (alias for `Stop-ContainerComposePodman`)
- [pcl](pcl.md) - Shows container logs using compose (Podman-first). (alias for `Get-ContainerComposeLogsPodman`)
- [pcu](pcu.md) - Starts container services using compose (Podman-first). (alias for `Start-ContainerComposePodman`)
- [pprune](pprune.md) - Prunes unused container system resources (Podman-first). (alias for `Clear-ContainerSystemPodman`)

### 30-open (1 aliases)

- [open](open.md) - Opens files or URLs using the system's default application. (alias for `Open-Item`)

### 33-aliases (2 aliases)

- [la](la.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhancedAll`)
- [ll](ll.md) - Enables user-defined aliases and helper functions for enhanced shell experience. (alias for `Get-ChildItemEnhanced`)

### 44-git (3 aliases)

- [Git-CurrentBranch](Git-CurrentBranch.md) - profile.d/44-git.ps1 (alias for `Get-GitCurrentBranch`)
- [Git-StatusShort](Git-StatusShort.md) - profile.d/44-git.ps1 (alias for `Get-GitStatusShort`)
- [Prompt-GitSegment](Prompt-GitSegment.md) - profile.d/44-git.ps1 (alias for `Format-PromptGitSegment`)

### 61-eza (11 aliases)

- [l](l.md) - Lists directory contents using eza (short alias). (alias for `Get-ChildItemEzaShort`)
- [la](la.md) - Lists all directory contents including hidden files using eza. (alias for `Get-ChildItemEzaAll`)
- [lg](lg.md) - Lists directory contents with git status using eza. (alias for `Get-ChildItemEzaGit`)
- [ll](ll.md) - Lists directory contents in long format using eza. (alias for `Get-ChildItemEzaLong`)
- [lla](lla.md) - Lists all directory contents in long format using eza. (alias for `Get-ChildItemEzaAllLong`)
- [llg](llg.md) - Lists directory contents in long format with git status using eza. (alias for `Get-ChildItemEzaLongGit`)
- [ls](ls.md) - Lists directory contents using eza. (alias for `Get-ChildItemEza`)
- [lS](lS.md) - Lists directory contents sorted by size using eza. (alias for `Get-ChildItemEzaBySize`)
- [lt](lt.md) - Lists directory contents in tree format using eza. (alias for `Get-ChildItemEzaTree`)
- [lta](lta.md) - Lists all directory contents in tree format using eza. (alias for `Get-ChildItemEzaTreeAll`)
- [ltime](ltime.md) - Lists directory contents sorted by modification time using eza. (alias for `Get-ChildItemEzaByTime`)

### 62-navi (4 aliases)

- [cheats](cheats.md) - Alias for `navi` (alias for `navi`)
- [navib](navib.md) - Finds the best matching command from navi cheatsheets. (alias for `Invoke-NaviBest`)
- [navip](navip.md) - Prints commands from navi cheatsheets without executing them. (alias for `Invoke-NaviPrint`)
- [navis](navis.md) - Searches navi cheatsheets interactively. (alias for `Invoke-NaviSearch`)

### 63-gum (5 aliases)

- [choose](choose.md) - Shows an interactive selection menu using gum. (alias for `Invoke-GumChoose`)
- [confirm](confirm.md) - Shows a confirmation prompt using gum. (alias for `Invoke-GumConfirm`)
- [input](input.md) - Shows an input prompt using gum. (alias for `Invoke-GumInput`)
- [spin](spin.md) - Shows a spinner while executing a script block using gum. (alias for `Invoke-GumSpin`)
- [style](style.md) - Styles text output using gum. (alias for `Invoke-GumStyle`)

### 64-bottom (6 aliases)

- [htop](htop.md) - Launches bottom system monitor. (alias for `btm`)
- [htop](htop.md) - Launches bottom system monitor. (alias for `bottom`)
- [monitor](monitor.md) - Launches bottom system monitor. (alias for `btm`)
- [monitor](monitor.md) - Launches bottom system monitor. (alias for `bottom`)
- [top](top.md) - Launches bottom system monitor. (alias for `btm`)
- [top](top.md) - Launches bottom system monitor. (alias for `bottom`)

### 65-procs (2 aliases)

- [ps](ps.md) - Lists processes with procs. (alias for `procs`)
- [psgrep](psgrep.md) - Searches processes with procs. (alias for `procs`)

### 66-dust (2 aliases)

- [diskusage](diskusage.md) - Shows disk usage with dust. (alias for `dust`)
- [du](du.md) - Shows disk usage with dust. (alias for `dust`)

### 67-uv (4 aliases)

- [pip](pip.md) - Python package manager using uv instead of pip. (alias for `Invoke-Pip`)
- [uvrun](uvrun.md) - Runs Python commands in temporary virtual environments using uv. (alias for `Invoke-UVRun`)
- [uvtool](uvtool.md) - Installs Python tools globally using uv. (alias for `Install-UVTool`)
- [uvvenv](uvvenv.md) - Creates Python virtual environments using uv. (alias for `New-UVVenv`)

### 68-pixi (3 aliases)

- [pxadd](pxadd.md) - Installs packages using pixi. (alias for `Invoke-PixiInstall`)
- [pxrun](pxrun.md) - Runs commands in the pixi environment. (alias for `Invoke-PixiRun`)
- [pxshell](pxshell.md) - Activates the pixi shell environment. (alias for `Invoke-PixiShell`)

### 69-pnpm (5 aliases)

- [npm](npm.md) - Alias for `pnpm` (alias for `pnpm`)
- [pnadd](pnadd.md) - Installs packages using pnpm. (alias for `Invoke-PnpmInstall`)
- [pndev](pndev.md) - Installs development packages using pnpm. (alias for `Invoke-PnpmDevInstall`)
- [pnrun](pnrun.md) - Runs npm scripts using pnpm. (alias for `Invoke-PnpmRun`)
- [yarn](yarn.md) - Alias for `pnpm` (alias for `pnpm`)

### 74-enhanced-history (1 aliases)

- [fh](fh.md) - Quick search in command history. (alias for `Find-HistoryQuick`)

### 75-system-monitor (6 aliases)

- [cpuinfo](cpuinfo.md) - Shows detailed CPU information and usage. (alias for `Show-CPUInfo`)
- [diskinfo](diskinfo.md) - Shows detailed disk usage information. (alias for `Show-DiskInfo`)
- [meminfo](meminfo.md) - Shows detailed memory usage information. (alias for `Show-MemoryInfo`)
- [netinfo](netinfo.md) - Shows detailed network information. (alias for `Show-NetworkInfo`)
- [sysinfo](sysinfo.md) - Shows a comprehensive system status dashboard. (alias for `Show-SystemDashboard`)
- [sysstat](sysstat.md) - Shows a compact system status overview. (alias for `Show-SystemStatus`)

### 76-smart-navigation (6 aliases)

- [b](b.md) - Goes back to the previous directory. (alias for `Set-LocationBack`)
- [bm](bm.md) - Lists all directory bookmarks. (alias for `Show-DirectoryBookmarks`)
- [c](c.md) - Enhanced change directory with navigation tracking. (alias for `Set-LocationTracked`)
- [cd](cd.md) - Enhanced change directory with navigation tracking. (alias for `Set-LocationTracked`)
- [f](f.md) - Goes forward in the navigation history. (alias for `Set-LocationForward`)
- [j](j.md) - Quick directory jumping alias. (alias for `Jump-DirectoryQuick`)

## Generation

This documentation was generated from the comment-based help in the profile fragments.
