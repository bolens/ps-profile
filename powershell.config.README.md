# powershell.config.json

This file contains PowerShell preferences for the distribution. JSON does not
support comments; to document settings we keep this README alongside it.

Current content:

    {"Microsoft.PowerShell:ExecutionPolicy":"RemoteSigned"}

Meaning:

- Microsoft.PowerShell:ExecutionPolicy — sets the PowerShell execution policy for
  this user/machine when using PowerShell Core. "RemoteSigned" allows running
  local scripts and requires that downloaded scripts are signed.

Suggestions:

- If you prefer a stricter policy, consider `AllSigned` (requires signing of
  all scripts).
- For local development machines, `RemoteSigned` is a good compromise.
- You can also set other PS engine preferences here. See `Set-ExecutionPolicy`
  and `about_Execution_Policies` in PowerShell for more information.

Note: Changes to `powershell.config.json` take effect for PowerShell Core
starting after a new shell is launched. Use `Get-ExecutionPolicy -List` to view
current effective policies.
