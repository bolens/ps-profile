# Developer Guides

Guides for developing, testing, and operating the PowerShell profile.

## Getting Started

| Guide | When to use |
| ----- | ----------- |
| [Development Quick Start](DEVELOPMENT_QUICK_START.md) | Fast profile reload during iterative work |
| [Development Guide](DEVELOPMENT.md) | Setup, workflow, advanced test runner features |
| [Testing Guide](TESTING.md) | **Primary** testing reference — structure, runner flags, coverage |
| [Testing Patterns](../examples/TESTING_PATTERNS.md) | Copy-paste test examples |
| [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md) | Stubbing commands, network, environment |
| [Coverage Verification](VERIFY_COVERAGE.md) | Per-module `analyze-coverage.ps1` checks |
| [Tool Requirements](TOOL_REQUIREMENTS.md) | Optional tools and test skips |

## Architecture & Loading

| Guide | When to use |
| ----- | ----------- |
| [Fragment Command Access](FRAGMENT_COMMAND_ACCESS.md) | On-demand loading and standalone wrappers |
| [Module Loading Standard](MODULE_LOADING_STANDARD.md) | `Import-FragmentModule` / `Import-FragmentModules` |
| [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md) | SQLite fragment cache, pre-warming, utilities |
| [Fragment Loading Optimization](FRAGMENT_LOADING_OPTIMIZATION.md) | Startup and fragment load strategies |
| [SQLite Databases](SQLITE_DATABASES.md) | Persistent cache, metrics, and history databases |
| [Parallel Loading State Merge Analysis](PARALLEL_LOADING_STATE_MERGE_ANALYSIS.md) | Why parallel runspace state merge is hard |

See also [ARCHITECTURE.md](../../ARCHITECTURE.md) for loader design and implemented optimizations.

## Code Quality

| Guide | When to use |
| ----- | ----------- |
| [Error Handling Standard](ERROR_HANDLING_STANDARD.md) | Structured errors, logging, color conventions |
| [Type Safety Guide](TYPE_SAFETY.md) | Enums, classes, validation, strict mode |
| [Function Naming Exceptions](FUNCTION_NAMING_EXCEPTIONS.md) | Approved naming deviations |
| [Security Allowlist](SECURITY_ALLOWLIST.md) | Intentional PSScriptAnalyzer suppressions |
| [Module Documentation Template](MODULE_DOCUMENTATION_TEMPLATE.md) | Template for module comment-based help |

## Preferences & Install Hints

| Guide | When to use |
| ----- | ----------- |
| [Preference-Aware Install Hints](PREFERENCE_AWARE_INSTALL_HINTS.md) | User preferences, hints API, integration points |

## Performance

| Guide | When to use |
| ----- | ----------- |
| [Profile Load Time Optimization](PROFILE_LOAD_TIME_OPTIMIZATION.md) | **Start here** — disable fragments, env tuning, quick wins |
| [Profile Performance Optimization](PROFILE_PERFORMANCE_OPTIMIZATION.md) | Code-level optimization opportunities |
| [Development Performance](DEVELOPMENT_PERFORMANCE.md) | Faster iteration while developing the profile |
| [Prompt Performance Troubleshooting](PROMPT_PERFORMANCE_TROUBLESHOOTING.md) | Slow or broken prompts |

## Documentation Maintenance

| Task | When |
| ---- | ---- |
| `task generate-docs` | After changing comment-based help on profile functions (full regen) |
| `task generate-docs-incremental` | Day-to-day help edits (parses/writes only changed sources) |
| `task generate-fragment-readmes` | After changing fragment behavior or exports |
| `task drift-link` | After editing guides/tests/sources they document, or after `generate-docs` |
| `task drift-check` | Before commits (`quality-check` runs this automatically) |

Drift links guides and tests to source files in `drift.lock`. Scripts:

- `scripts/utils/code-quality/link-guide-drift.ps1`
- `scripts/utils/code-quality/link-test-drift.ps1`
- `scripts/utils/code-quality/link-api-drift.ps1`

## Related Documentation

- [docs/README.md](../README.md) — Documentation index
- [API Reference](../api/README.md)
- [Fragment Documentation](../fragments/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [AGENTS.md](../../AGENTS.md)
