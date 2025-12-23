# ===============================================
# Modern CLI tools helper functions
# Modern CLI tool wrappers with command detection
# ===============================================

<#
Register modern CLI tools helpers using standardized Register-ToolWrapper function.
This replaces the previous repetitive pattern with a clean, maintainable approach.
#>

# bat - cat clone with syntax highlighting and Git integration
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

# fd - find files and directories
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'

# http - command-line HTTP client
Register-ToolWrapper -FunctionName 'http' -CommandName 'http' -WarningMessage 'httpie (http) not found' -InstallHint 'Install with: scoop install httpie'

# zoxide - smarter cd command
Register-ToolWrapper -FunctionName 'zoxide' -CommandName 'zoxide' -InstallHint 'Install with: scoop install zoxide'

# delta - syntax-highlighting pager for git
Register-ToolWrapper -FunctionName 'delta' -CommandName 'delta' -InstallHint 'Install with: scoop install delta'

# tldr - simplified man pages
Register-ToolWrapper -FunctionName 'tldr' -CommandName 'tldr' -InstallHint 'Install with: scoop install tldr'

# procs - modern replacement for ps
Register-ToolWrapper -FunctionName 'procs' -CommandName 'procs' -InstallHint 'Install with: scoop install procs'

# dust - more intuitive du command
Register-ToolWrapper -FunctionName 'dust' -CommandName 'dust' -InstallHint 'Install with: scoop install dust'

