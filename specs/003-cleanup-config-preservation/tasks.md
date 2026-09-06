# Tasks

- [x] T001 Trace the observed deletion to the test cleanup list.
- [x] T002 Reproduce the failure with a disposable preservation fixture.
- [x] T003 Remove the incorrect artifact entry and pass all 55 focused TestSupport tests.
- [x] T005 Run the candidate-wide native quality gate.
- [x] T004 Separately self-review cleanup behavior and fixture isolation.

Hosted delivery and current-head CI remain owned by the PR.

The red run reproduced configuration deletion. Its second failure was an existing
missing-root fixture inheriting the runner’s explicit repository override; clear
and restore that override within the fixture without changing resolver behavior.

The remaining negative-fixture failure came from an environment-owned empty
/tmp/.git marker. The fixture now models absent markers and restores the explicit
root override; product repository discovery behavior is unchanged.

Concurrent main commit 69fa516dbc0ebf08eab7d9ae00c6f051cb589ebe independently
removed the same cleanup entry before this PR merged. The candidate was rebased
onto that correction and retains the preservation regression, missing-root
fixture isolation, and specification evidence.
