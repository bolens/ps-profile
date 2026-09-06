# VS Code for ps-profile

Open this repository as a folder, or add it as a folder in a multi-root workspace.
Install the recommendations from the Extensions view. Use **Tasks: Run Task** for
the commands below. Tasks run from this repository unless they state another directory.

Use the tool versions documented by the repository. Launch VS Code from the
prepared development shell, or reopen in the existing dev container when available.
Extension recommendations do not install command-line dependencies.

| Task | Command |
| --- | --- |
| quality-check | `pnpm run quality-check` |
| check-task-parity | `pwsh -NoProfile -File scripts/utils/task-parity/check-task-parity.ps1` |
| test-unit | `pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -Parallel` |
| Check diff whitespace | `git diff --check` |

Debug configurations are available in **Run and Debug**. Choose a test or help
configuration for development. The selected-file configurations run the selected
script, so select a test or an intended entry point.

Canonical package scripts provide aggregate task behavior. `quality-check` runs
the repository quality gate, including its formatter. Other existing maintenance
tasks remain explicit actions in the task picker. PowerShell profile loading is disabled.
