# Playbook 04 - CI/CD, Testing, and PR Flow

## Objective

Enforce quality and safety gates for all changes before merge progression.

## Inputs

- [CONTEXT.md](../../../../CONTEXT.md)
- [Phase 04](../phases/04-ci-cd-testing-pr-flow.md)
- Execution outputs from Playbook 03

## Preconditions

- CI checks are configured and passing on baseline.
- Risk labels map to mandatory human checkpoints.
- Auto-merge remains disabled by default.

## Procedure

### Cloud-first lane

1. Ensure provenance metadata is attached to PRs.
2. Run lint, tests, and security checks.
3. Route risky PRs through human-gate merge path.
4. Record cost and quality metrics for unlock analysis.

### Local-first (Lenovo P52) lane

1. Run critical test subset first.
2. Offload heavy validation if local limits are reached.
3. Keep PR size small for clear reviewability.
4. Route risk labels through mandatory human-gate.

### Local-first (Gigabyte) lane

1. Run full validation suites where capacity allows.
2. Use batch windows for non-urgent validation.
3. Apply same risk gate policy as other lanes.
4. Record performance and quality evidence.

## Decision gates

- Gate G1: All mandatory CI checks are green.
- Gate G2: No unresolved high or critical security findings.
- Gate G3: Required human approvals are present.
- Gate G4: KPI unlock criteria are met before any auto-merge.

## Failure modes

- Flaky checks block deterministic merge flow.
- Missing provenance breaks traceability.
- Premature auto-merge unlock increases escaped defects.

## Rollback

1. Disable auto-merge for all classes.
2. Revert to full human-gate merge policy.
3. Rebaseline KPI window before reconsidering unlock.

## Outputs

- Gate-compliant PRs
- Merge decisions with explicit evidence
- KPI dataset for unlock governance

## Owners and SLA

|Role|Responsibility|SLA|
|---|---|---|
|CI owner|Pipeline health and reliability|4 hours|
|Security owner|Security gate sign-off|1 business day|
|Engineering lead|Merge policy decisions|1 business day|

## Evidence checklist

- [ ] CI, test, and security results are attached to PR
- [ ] Traceability to source issue is present
- [ ] Human-gate approvals are recorded for risky changes
- [ ] Unlock decisions reference rolling KPI evidence
