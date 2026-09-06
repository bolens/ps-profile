# Documentation

PowerShell startup, shared libraries, generated API docs, and local storage.

## Start here

| Need | Owning document |
| --- | --- |
| Use the project | [README.md](../README.md) |
| Change the repository | [AGENTS.md](../AGENTS.md) |
| Deliver or recover | [RELEASING.md](../RELEASING.md) |
| Plan substantial changes | [.specify/memory/project-guide.md](../.specify/memory/project-guide.md) |
| Non-negotiable constraints | [.specify/memory/constitution.md](../.specify/memory/constitution.md) |

## Architecture

[ARCHITECTURE.md](../ARCHITECTURE.md) owns lazy fragment loading and shared library boundaries. Keep
the root profile small and preserve canonical module loading, strict behavior, and idempotent
fragments. Generated [API documentation](api/README.md) comes from source help, while hand-authored
guides explain decisions and failure modes.

## Deployment and recovery

[Profile setup](../PROFILE_README.md) owns installation and configuration.
[RELEASING.md](../RELEASING.md) owns semantic-release delivery and recovery. Test with isolated
roots and `-NoProfile`. A checked-out update does not establish that the active user profile loaded
it.

## Database and state

[SQLite databases](guides/SQLITE_DATABASES.md) distinguishes available helpers from
absent optional backends and owns persistence guidance. [Fragment cache
usage](guides/FRAGMENT_CACHE_USAGE.md) owns disposable cache behavior. Command history and retained
metrics are user data, so they cannot be treated like replaceable parsed-fragment caches.

## Documentation maintenance

Keep decisions, invariants, failure modes, and recovery requirements in the owning document. Link to
commands, defaults, schemas, and generated catalogs instead of copying them. Change the owner and
affected references together. Update this index when adding or moving a guide, and verify relative
links and heading anchors. Historical specs and audits describe their recorded revision, not current
runtime proof. A topic without an implementation stays explicitly unimplemented.

## Topic guides

- [API reference](api/README.md): generated functions and aliases.
- [Fragment index](fragments/README.md): fragment behavior and load order.
- [Developer guides](guides/README.md): authoring, performance, and failure handling.
- [Examples](examples/README.md): repository conventions in working code.
- [Testing](guides/TESTING.md): runner selection, isolation, and coverage.
- [Contributing](../CONTRIBUTING.md): local workflow and required validation.
- [Security](../SECURITY.md): trust boundaries and reporting.

## Documentation Generation

API and fragment reference pages are generated from source. This index and maintainer guides are
hand-authored:

- **API Documentation**: Run `task generate-docs` or `pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1`
- **Fragment Documentation**: Run `task generate-fragment-readmes` or `pwsh -NoProfile -File scripts/utils/docs/generate-fragment-readmes.ps1`
- **All Documentation**: Run `task all-docs` to generate both

API documentation generation returns a validation failure if any function, alias, index, or cleanup
step fails; partial output is never reported as a successful run.

After editing guides, tests, or the source files they describe—or after `generate-docs`—refresh
drift bindings:

```powershell
task drift-link    # updates drift.lock for tests, guides, and docs/api
task drift-check   # included in quality-check
```

After a full API doc regeneration, run `task drift-link` again so `docs/api/**` source anchors stay
current.
