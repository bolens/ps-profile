# Implementation Roadmap

This document provides a clear, prioritized order for implementing the comprehensive module expansion plan, fragment numbering migration, and refactoring opportunities.

## Table of Contents

1. [Implementation Phases](#implementation-phases)
2. [Phase Dependencies](#phase-dependencies)
3. [Critical Path](#critical-path)
4. [Recommended Order](#recommended-order)
5. [Progress Tracking](#progress-tracking)

---

## Implementation Phases

### Phase 0: Foundation (CRITICAL - Do First)

**Goal**: Establish robust infrastructure before adding new modules

**Duration**: 2-3 weeks

**Tasks**:

1. **Module Loading Standardization** ⚠️ **HIGHEST PRIORITY**

   - Implement `Import-FragmentModule` with all features
   - Add path caching infrastructure
   - Add dependency validation
   - Add retry logic
   - **Why First**: Addresses ongoing module loading issues, affects all fragments
   - **Files**: Create `profile.d/bootstrap/ModuleLoading.ps1`
   - **Tests**: 100% coverage required
   - **Dependencies**: None (foundation)

2. **Tool Wrapper Standardization**

   - Implement `Register-ToolWrapper` function
   - **Why Second**: Reduces boilerplate for all new modules
   - **Files**: `profile.d/bootstrap/FunctionRegistration.ps1`
   - **Tests**: 100% coverage required
   - **Dependencies**: Module loading (for error handling)

3. **Command Detection Standardization**

   - Migrate to `Test-CachedCommand` everywhere
   - Make `Test-HasCommand` an alias for backward compatibility
   - **Why Third**: Performance improvement, affects all modules
   - **Files**: All fragments (migrate incrementally)
   - **Tests**: Update existing tests
   - **Dependencies**: None (can do in parallel)

4. **Test Coverage Analysis** ⚠️ **CRITICAL FOR QUALITY**

   - Generate comprehensive coverage report
   - Identify functions with < 80% coverage
   - List missing test cases for uncovered code
   - Prioritize coverage gaps by module importance
   - **Why Critical**: Ensures quality baseline before expansion
   - **Files**: Use existing test infrastructure
   - **Tools**: `scripts/utils/code-quality/run-pester.ps1 -Coverage`
   - **Dependencies**: None (can run in parallel with tasks 1-3)
   - **Reference**: See `TEST_VERIFICATION_PROGRESS.md` Phase 3

5. **Incremental Test Execution** (AS WE REFACTOR) ⚠️ **ONGOING**

   - Execute Priority 4 tests (Conversion tests: Data, Document, Media) - **Run as we refactor conversion modules**
   - Execute Priority 5 tests (Unit tests: 84 files) - **Run as we refactor related areas**
   - Execute Priority 6 tests (Performance tests: 6 files) - **Run as we refactor performance-critical areas**
   - Fix any failures discovered during refactoring
   - **Why Critical**: Ensures all existing code works, but we test incrementally as we refactor
   - **Strategy**: Test as we go, not as a separate blocking phase
   - **⚠️ CRITICAL: Use `scripts/utils/code-quality/analyze-coverage.ps1` for all test execution**
   - The `analyze-coverage.ps1` script:
     - Runs tests non-interactively (no user prompts)
     - Generates comprehensive coverage reports
     - Identifies per-file coverage gaps
     - Automatically matches test files to source files
     - Reports coverage percentages and identifies files < 80% coverage
   - **Example**: `pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/22-containers.ps1`
   - **Do NOT use `run-pester.ps1` directly** - always use `analyze-coverage.ps1` which provides coverage analysis
   - **Test-to-source mappings**: Mappings in `analyze-coverage.ps1` are maintained incrementally - add mappings when pattern matching fails or for multi-file tests
   - **Current Status**: Priority 1-3 complete (599/599 passing)
   - **Dependencies**: Coverage analysis (task 4) helps prioritize fixes
   - **Reference**: See `TEST_VERIFICATION_PROGRESS.md` Phase 5

6. **Test Documentation & Reporting** (ONGOING)

   - Generate execution reports after each refactoring batch using `analyze-coverage.ps1`
   - Document test coverage gaps as they're discovered (reported by `analyze-coverage.ps1`)
   - Update test improvement log incrementally
   - **Why Important**: Provides baseline metrics and tracking
   - **Strategy**: Document as we go, not as a final phase
   - **Tool**: Use `scripts/utils/code-quality/analyze-coverage.ps1` for all coverage reporting
   - **Files**: Test reports (JSON from `analyze-coverage.ps1`), `TEST_VERIFICATION_PROGRESS.md`
   - **Dependencies**: Tasks 4-5 (ongoing as we refactor)
   - **Reference**: See `TEST_VERIFICATION_PROGRESS.md` Phase 6.1

**Deliverables**:

- ✅ Robust module loading system
- ✅ Standardized tool wrapper pattern
- ✅ Consistent command detection
- ✅ Complete test coverage analysis and report (80.27% coverage achieved)
- ✅ All Priority 1-3 tests passing (599/599)
- ⏳ Priority 4-6 tests passing incrementally (as we refactor)
- ⏳ Test execution reports generated incrementally
- ✅ All foundation code tested (80.27% coverage, exceeds 75% target)

**Success Criteria**:

- All existing fragments can use new module loading
- No performance regression
- All Priority 1-3 tests pass (✅ 599/599 passing)
- Priority 4-6 tests pass incrementally as we refactor related areas
- **Strategy**: Test as we refactor, not as a separate blocking phase
- Coverage report shows > 80% coverage for critical modules
- Test execution report documents all test results
- Documentation complete

---

### Phase 1: Fragment Numbering Migration

**Goal**: Migrate from numbered to named fragments with explicit dependencies

**Duration**: 3-4 weeks

**Dependencies**: Phase 0 complete (need robust module loading)

**Tasks**:

1. **Update Fragment Loading Logic**

   - Update `Get-FragmentTiers` to use explicit tier declarations
   - Add `Get-FragmentTier` function
   - Update profile loader to use dependency-aware loading as primary
   - Add backward compatibility for numbered fragments
   - **Files**: `scripts/lib/fragment/FragmentLoading.psm1`, `Microsoft.PowerShell_profile.ps1`
   - **Tests**: Update fragment loading tests

2. **Migrate Core Fragments** (00-09)

   - `00-bootstrap.ps1` → `bootstrap.ps1` (Tier: core)
   - `01-env.ps1` → `env.ps1` (Tier: essential, Dependencies: bootstrap)
   - `02-files.ps1` → `files.ps1` (Tier: essential, Dependencies: bootstrap, env)
   - `05-utilities.ps1` → `utilities.ps1` (Tier: essential, Dependencies: bootstrap, env)
   - **Why First**: These are dependencies for everything else
   - **Apply Refactorings**: Use new `Import-FragmentModule` during migration

3. **Migrate Essential Fragments** (10-29)

   - `11-git.ps1` + `44-git.ps1` → `git.ps1` (consolidate, Tier: standard)
   - `22-containers.ps1` → `containers.ps1` (Tier: standard)
   - `12-psreadline.ps1` → `psreadline.ps1` (Tier: essential)
   - `19-fzf.ps1` → `fzf.ps1` (Tier: standard)
   - `20-gh.ps1` → `gh.ps1` (Tier: standard)
   - **Apply Refactorings**: Use new module loading, tool wrappers

4. **Migrate Standard Fragments** (30-69)

   - Language modules (Go, Rust, PHP, etc.)
   - Cloud modules (AWS, Azure, GCloud)
   - Development tools
   - **Apply Refactorings**: Standardize patterns

5. **Migrate Optional Fragments** (70-99)

   - Advanced features
   - Specialized tools
   - **Apply Refactorings**: Standardize patterns

6. **Remove Backward Compatibility**
   - Remove numbered fragment support
   - Update all documentation
   - **Only after**: All fragments migrated and tested

**Deliverables**:

- ✅ All fragments renamed and migrated
- ✅ Explicit dependencies declared
- ✅ Tier declarations added
- ✅ All fragments use new module loading
- ✅ All tests pass
- ✅ Documentation updated

**Success Criteria**:

- Profile loads correctly with named fragments
- Dependency resolution works correctly
- No performance regression
- All tests pass
- Documentation reflects new naming

---

### Phase 2: High-Priority New Modules

**Goal**: Implement most-used new modules

**Duration**: 4-6 weeks

**Dependencies**: Phase 1 complete (need named fragments)

**Tasks** (in order):

1. **Security Tools** (`security-tools.ps1`)

   - Critical for security scanning
   - Tools: gitleaks, trufflehog, osv-scanner, yara, clamav, dangerzone
   - **Tests**: 100% coverage required
   - **Dependencies**: bootstrap, env

2. **API Tools** (`api-tools.ps1`)

   - Essential for API development
   - Tools: bruno, postman, hurl, httptoolkit
   - **Tests**: 100% coverage required
   - **Dependencies**: bootstrap, env

3. **Database Clients** (`database-clients.ps1`)

   - Enhance existing database support
   - Tools: mongodb-compass, sql-workbench, hasura-cli, supabase
   - **Tests**: 100% coverage required
   - **Dependencies**: bootstrap, env, database

4. **Language Modules** (Priority order):

   - `lang-rust.ps1` (enhance existing rustup.ps1)
   - `lang-python.ps1` (enhance existing uv.ps1, pixi.ps1)
   - `lang-go.ps1` (enhance existing go.ps1)
   - `lang-java.ps1` (new)
   - **Tests**: 100% coverage for each
   - **Dependencies**: bootstrap, env

5. **Git Enhanced** (`git-enhanced.ps1`)

   - Enhance existing git.ps1
   - Tools: git-tower, gitkraken, git-cliff, gitoxide, jj
   - **Tests**: 100% coverage required
   - **Dependencies**: bootstrap, env, git

6. **Media Tools** (`media-tools.ps1`)
   - Common media operations
   - Tools: ffmpeg, handbrake, mkvtoolnix, mp3tag, picard
   - **Tests**: 100% coverage required
   - **Dependencies**: bootstrap, env

**Deliverables**:

- ✅ 6+ new modules implemented
- ✅ All modules tested (100% coverage)
- ✅ All modules documented
- ✅ Performance benchmarks met

**Success Criteria**:

- All modules load correctly
- All functions work as expected
- All tests pass
- No performance regression
- Documentation complete

---

### Phase 3: Medium-Priority Modules

**Goal**: Implement frequently-used modules

**Duration**: 4-6 weeks

**Dependencies**: Phase 2 complete

**Tasks** (in order):

1. **Network Analysis** (`network-analysis.ps1`)
2. **Cloud Enhanced** (`cloud-enhanced.ps1`)
3. **Containers Enhanced** (`containers-enhanced.ps1`)
4. **Kubernetes Enhanced** (`kubernetes-enhanced.ps1`)
5. **IAC Tools** (`iac-tools.ps1`)
6. **Content Tools** (`content-tools.ps1`)

**Deliverables**: Same as Phase 2

---

### Phase 4: Low-Priority Modules

**Goal**: Implement specialized modules

**Duration**: 6-8 weeks

**Dependencies**: Phase 3 complete

**Tasks** (in order):

1. **Game Emulators** (`game-emulators.ps1`)
2. **Reverse Engineering** (`re-tools.ps1`)
3. **Mobile Development** (`mobile-dev.ps1`)
4. **Game Development** (`game-dev.ps1`)
5. **3D/CAD Tools** (`3d-cad.ps1`)
6. **Terminal Enhanced** (`terminal-enhanced.ps1`)
7. **Editors** (`editors.ps1`)

**Deliverables**: Same as Phase 2

---

### Phase 5: Enhanced Existing Modules

**Goal**: Enhance existing modules with new functionality

**Duration**: 3-4 weeks

**Dependencies**: Can run in parallel with Phases 2-4

**Tasks** (in order):

1. **AWS Module Enhancements** (`aws.ps1`)

   - Credential management, cost tracking, resource listing

2. **Git Module Enhancements** (`git.ps1`)

   - Worktrees, branch cleanup, statistics

3. **Container Module Enhancements** (`containers.ps1`)

   - Cleanup, log export, health checks

4. **Kubernetes Module Enhancements** (`kubectl.ps1`, `kube.ps1`)

   - Enhanced pod management, port forwarding

5. **Modern CLI Module Enhancements** (`modern-cli.ps1`)

   - Wrapper functions for existing tools

6. **Database Module Enhancements** (`database.ps1`)
   - Connection helpers, query execution, backup/restore

**Deliverables**:

- ✅ Enhanced functionality added
- ✅ Backward compatibility maintained
- ✅ All tests pass
- ✅ Documentation updated

---

### Phase 6: Pattern Extraction (Refactoring)

**Goal**: Extract common patterns into base modules

**Duration**: 2-3 weeks

**Dependencies**: Phases 2-5 complete (need examples to extract patterns from)

**Tasks**:

1. **Cloud Provider Base Module**

   - Extract common patterns from AWS, Azure, GCloud
   - Create `cloud-base.ps1`
   - Refactor cloud modules to use base

2. **Language Module Base**

   - Extract common patterns from language modules
   - Create `language-base.ps1`
   - Refactor language modules to use base

3. **Error Handling Standardization**
   - Standardize error handling across all modules
   - Update all modules to use standard patterns

**Deliverables**:

- ✅ Base modules created
- ✅ Existing modules refactored
- ✅ Code duplication reduced
- ✅ All tests pass

---

## Phase Dependencies

```
Phase 0 (Foundation)
  └─> Phase 1 (Fragment Migration)
        └─> Phase 2 (High-Priority Modules)
              └─> Phase 3 (Medium-Priority Modules)
                    └─> Phase 4 (Low-Priority Modules)

        └─> Phase 5 (Enhanced Modules) [Can run in parallel with 2-4]

        └─> Phase 6 (Pattern Extraction) [Requires 2-5 complete]
```

**Critical Path**: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4

**Parallel Opportunities**:

- Phase 5 can run in parallel with Phases 2-4
- Some Phase 2 modules can be developed in parallel
- Phase 0 tasks 2-3 can run in parallel with task 1

---

## Recommended Order

### Week 1-3: Foundation (Phase 0)

**Week 1**:

- [ ] Implement `Import-FragmentModule` with all features
- [ ] Add path caching infrastructure
- [ ] Write comprehensive tests (100% coverage)
- [ ] Test with existing fragments
- [ ] Generate test coverage report (Priority 1-3 baseline)
- [ ] Analyze coverage gaps (identify functions with < 80% coverage)

**Week 2**:

- [ ] Implement `Register-ToolWrapper`
- [ ] Migrate `modern-cli.ps1` to use it
- [ ] Write tests
- [ ] Update documentation
- [ ] **Begin refactoring conversion modules** (test Priority 4 as we go)

**Week 3**:

- [ ] Standardize command detection
- [ ] Migrate high-traffic fragments first
- [ ] Update tests
- [ ] **Continue refactoring with incremental testing**:
  - Execute Priority 4 tests as we refactor conversion modules
  - Execute Priority 5 tests as we refactor unit test areas
  - Execute Priority 6 tests as we refactor performance-critical code
- [ ] Fix any failures discovered during refactoring
- [ ] Generate test execution reports incrementally
- [ ] Performance validation

### Week 4-7: Fragment Migration (Phase 1)

**Week 4**:

- [ ] Update fragment loading logic
- [ ] Add tier support
- [ ] Migrate core fragments (00-09)
- [ ] Test dependency resolution

**Week 5**:

- [ ] Migrate essential fragments (10-29)
- [ ] Consolidate git modules
- [ ] Test all migrations

**Week 6**:

- [ ] Migrate standard fragments (30-69)
- [ ] Apply refactorings during migration
- [ ] Test thoroughly

**Week 7**:

- [ ] Migrate optional fragments (70-99)
- [ ] Remove backward compatibility
- [ ] Final testing and documentation

### Week 8-13: High-Priority Modules (Phase 2)

**Week 8**:

- [ ] Implement `security-tools.ps1`
- [ ] Implement `api-tools.ps1`
- [ ] Write tests (100% coverage)

**Week 9**:

- [ ] Implement `database-clients.ps1`
- [ ] Implement `lang-rust.ps1`
- [ ] Write tests

**Week 10**:

- [ ] Implement `lang-python.ps1`
- [ ] Implement `lang-go.ps1`
- [ ] Write tests

**Week 11**:

- [ ] Implement `lang-java.ps1`
- [ ] Implement `git-enhanced.ps1`
- [ ] Write tests

**Week 12**:

- [ ] Implement `media-tools.ps1`
- [ ] Write tests
- [ ] Performance validation

**Week 13**:

- [ ] Integration testing
- [ ] Documentation
- [ ] Code review

### Week 14-19: Medium-Priority Modules (Phase 3)

**Week 14-15**: Network Analysis, Cloud Enhanced
**Week 16-17**: Containers Enhanced, Kubernetes Enhanced
**Week 18**: IAC Tools
**Week 19**: Content Tools, Integration Testing

### Week 20-27: Low-Priority Modules (Phase 4)

**Week 20-21**: Game Emulators, Reverse Engineering
**Week 22-23**: Mobile Development, Game Development
**Week 24-25**: 3D/CAD Tools, Terminal Enhanced
**Week 26**: Editors
**Week 27**: Integration Testing, Documentation

### Week 28-31: Enhanced Modules (Phase 5)

**Week 28**: AWS, Git enhancements
**Week 29**: Containers, Kubernetes enhancements
**Week 30**: Modern CLI, Database enhancements
**Week 31**: Testing, Documentation

### Week 32-34: Pattern Extraction (Phase 6)

**Week 32**: Cloud provider base module
**Week 33**: Language module base
**Week 34**: Error handling standardization, Final testing

---

## Progress Tracking

See `IMPLEMENTATION_PROGRESS.md` for detailed progress tracking.

---

## Success Metrics

### Phase 0 Success

- ✅ Module loading issues resolved
- ✅ < 50ms startup impact per module
- ✅ 100% test coverage for foundation code
- ✅ All Priority 1-3 tests passing (599/599)
- ⏳ Priority 4-6 tests passing incrementally (as we refactor)
- ✅ Coverage report shows > 80% coverage for critical modules
- ✅ Test execution report generated

### Phase 1 Success

- ✅ All fragments migrated to named convention
- ✅ Dependency resolution works correctly
- ✅ No performance regression
- ✅ All tests pass

### Phase 2-4 Success

- ✅ All modules implemented
- ✅ 100% test coverage
- ✅ Documentation complete
- ✅ Performance benchmarks met

### Overall Success

- ✅ 39+ new modules implemented
- ✅ 6 modules enhanced
- ✅ All code follows standards
- ✅ No performance regression
- ✅ Comprehensive test coverage

---

## Risk Mitigation

### Risks

1. **Module Loading Issues Continue**

   - **Mitigation**: Implement Phase 0 first, thoroughly test
   - **Contingency**: Keep old pattern as fallback during transition

2. **Fragment Migration Breaks Profile**

   - **Mitigation**: Migrate incrementally, test after each batch
   - **Contingency**: Keep numbered fragments working during transition

3. **Performance Regression**

   - **Mitigation**: Benchmark before/after each phase
   - **Contingency**: Optimize or rollback if needed

4. **Scope Creep**
   - **Mitigation**: Stick to plan, defer non-critical items
   - **Contingency**: Adjust timeline if needed

---

## Notes

- **Start with Phase 0** - Foundation is critical
- **Test thoroughly** - 100% coverage required
- **Document as you go** - Don't defer documentation
- **Incremental migration** - Don't try to do everything at once
- **Performance monitoring** - Track startup time throughout
- **Code reviews** - Review each phase before moving to next
