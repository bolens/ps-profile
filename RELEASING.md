# Release playbook

PS Profile uses semantic-release from protected `main`; the semantic-release configuration is
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
It generates `CHANGELOG.md` as a downloadable release asset without committing
it back to `main`. The tag stays on the reviewed merge commit. Update the tracked
changelog only through the normal generated-changelog PR process.

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

## Branch protection

The default branch requires pull requests, resolved conversations, linear
history, and an up-to-date branch with passing required checks, including
`Pester result` and `commit-message-check`. These rules also apply to
administrators; force pushes and branch deletion are disabled. Zero approving
reviews are required because this is a solo-maintainer repository; review the
complete diff before merging.

Keep required checks available on every pull request. Filter expensive work
inside jobs or use an always-running result job that rejects failures and
cancellations. Update the protection settings when renaming required jobs.

## Source lint

The Source lint workflow checks maintained python, shell files selected by
[`.github/source-lint.json`](.github/source-lint.json) on every pull request
and push to `main`. Existing native checks remain part of the merge gate.
Use the [shared local reproduction instructions](https://github.com/bolens/.github/blob/7603518f305fb76f7bb1b9979f2692521f633b82/docs/source-lint.md)
with the same tooling revision pinned in
[the workflow](.github/workflows/source-lint.yml). Review exclusions when adding
source files; generated and imported files retain their native validation.
Require the new check to pass on the current PR head before merging.
