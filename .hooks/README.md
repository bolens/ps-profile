# Enabling pre-commit validation

This repository includes an optional pre-commit hook that runs `scripts/git/pre-commit.ps1`,
which formats code first, then runs validation checks (`scripts/checks/validate-profile.ps1`).
The hook is disabled by default. To enable it locally:

```powershell
# Create the enable marker (only for your local clone)
New-Item -ItemType File -Path .hooks\enable -Force
```

To disable it, remove the file:

```powershell
Remove-Item .hooks\enable
```

Notes:

- The enable file is intentionally not tracked by the repository so enabling is opt-in.
- You can add a copy to your global Git template if you want the hook enabled for new clones automatically.
