# Third-party notices

## License scope

The root MIT license covers original material authored by bolens. It does not
replace third-party licenses, copyright notices, trademarks, or service terms.
Imported and modified third-party material keeps its applicable upstream terms.

## GitHub Spec Kit

Imported `.specify/scripts/`, `.specify/templates/`, and
`.agents/skills/speckit-*` integration files retain GitHub's MIT copyright and
permission notice in [.specify/LICENSE](.specify/LICENSE). Include it when
copying these files. Project-authored memory documents have separate ownership.

## Dependency inputs

Dependency declarations are recorded in:

- `package.json`
- `requirements.txt`

## Redistribution

Keep applicable full license and copyright notices with copied source and
bundled dependencies, including minified JavaScript and compiled executables.
Use the exact dependency versions selected by the lockfile or build. Preserve
Apache NOTICE material and satisfy copyleft source requirements where they
apply. Development-only tools and separately installed programs keep their own
terms but are not automatically part of a distributed application.

This source inventory is not proof that every historical release, external
asset, fetched dataset, or built container has satisfied its license obligations.

[Dependency license texts](THIRD_PARTY_LICENSES.txt) are retained for the locked
production and optional dependency closure, including documentation workspaces.

## Unresolved package notices

The following exact package versions declare a license or are used by the
project, but a full applicable notice was not found in the published package or
its recorded source revision. They are not cleared by this inventory. Obtain the
missing notices or permission before redistributing the affected bundle.

- `base32-decode@1.0.0` declares `MIT`.
- `brotli@1.3.3` declares `MIT`.
- `int53@0.2.4` declares `BSD-3-Clause`.
- `to-data-view@2.0.0` declares `MIT`.
- `varint@5.0.2` declares `MIT`.

## Updating dependencies

When a lockfile or module version changes, refresh `THIRD_PARTY_LICENSES.txt`
from those exact package sources and review new license terms and NOTICE files.
Verify that source archives, compiled archives, native packages, containers, and
served browser bundles retain the notices for what they actually distribute.
Do not copy notice inventories between branches with different dependency locks.
