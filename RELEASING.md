# Release playbook

PS Profile uses semantic-release from protected `main`; `.releaserc.json` is
the release authority. Do not create versions or tags manually. Conventional
commit semantics determine whether the Release workflow publishes a version.

## Prepare and validate

Create a focused branch from current `origin/main`. Update `CHANGELOG.md` only
through the repository's configured changelog process, and update generated API
documentation through its generator. Use isolated `pwsh -NoProfile` tests; do
not load or modify the live profile.

```sh
make validate
make test
npm run check-task-parity
python3 scripts/check-changelog.py
```

Run the broader documented quality targets for cross-platform, dependency,
security, or performance changes. Record unavailable OS-specific coverage.

## Review and publish

Open a pull request, require every applicable check, resolve conversations, and
squash-merge. The squash commit message must accurately express release impact
because semantic-release consumes it. The push-triggered Release workflow owns
version calculation, tag creation, changelog/release notes, and publication.

## Verify and recover

Watch the Release workflow. If it publishes, verify the tag targets the merged
commit, release notes describe user impact, the published version is internally
consistent, and a clean isolated profile import succeeds on supported
platforms. If no release is expected, confirm the workflow intentionally exits
without one.

Never rerun semantic-release after changing history or move a published tag.
Fix a failed workflow configuration through a new PR; correct a public defect
with a new semantic-release-compatible commit and release.

Fleet policy: <https://github.com/bolens/.github/blob/main/RELEASING.md>.
