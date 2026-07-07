# Phase 04 - CI/CD, Testing, and PR Flow

## Objective

Enforce a quality gate chain for agent-generated and human-generated changes.
Start with 100% human-gate merges. Unlock auto-merge only by KPI evidence.

## Scope

- CI gate model and mandatory checks
- PR lifecycle and reviewer responsibilities
- Human-gate-first merge progression
- KPI-based unlock conditions for selective auto-merge

## Dependencies

- [Phase 01 - Governance and Preparation](./01-governance-and-prep.md)
- [Phase 03 - Label-driven Agent Orchestration](./03-label-driven-agent-orchestration.md)

## Entry criteria

- Orchestration flow is deterministic in pilot
- Risk labels map to checkpoint owners
- Baseline test and security scans are available

## Activities by strategy variant

### Cloud-first

- Enforce redaction and provenance metadata on generated changes
- Add token-cost telemetry to PR metadata
- Route high-risk cloud changes through elevated review

### Local-first (Lenovo P52)

- Prioritize critical tests first on constrained capacity
- Offload heavy validation when needed
- Keep PR scope small to reduce rework

### Local-first (Gigabyte)

- Run broader validation suites locally when cost-efficient
- Use larger batch validation windows
- Use capacity-aware queueing for validation throughput

## Deliverables

- CI gate sequence definition
- PR checklist with provenance and risk metadata
- Merge progression policy
- KPI threshold table for unlock decisions

## Weighted decision matrix

|Criterion|Weight|Cloud-first|Local Lenovo|Local Gigabyte|
|---|---|---|---|---|
|QA strength|30|Strong mandatory checks|Strong checks|Strong checks|
|Merge safety|25|Conservative unlock|Conservative unlock|Progressive unlock|
|Validation throughput|15|High with scalable CI|Limited|Medium-high|
|Cost efficiency|15|Needs budget control|Lower cost, slower|Better at scale|
|Predictability|15|High with fixed chain|Medium|High after tuning|

## KPI thresholds

Auto-merge is allowed only for low-risk classes and only if all thresholds
hold for a rolling 30-day window.

|KPI|Threshold to unlock selective auto-merge|
|---|---|
|CI first-pass rate|>= 95%|
|Escaped defects|<= 2%|
|Open high or critical security findings|0|
|Coverage on changed modules|>= 80%|
|Manual rollback incidents|<= 1% of merged PRs|
|Median PR cycle time stability|No degradation > 15% from baseline|

## Mandatory gates checklist

- [ ] Every PR links to source issue and labels
- [ ] Lint, tests, dependency checks, and security scans pass
- [ ] Risk-labeled PRs require explicit human approval
- [ ] Auto-merge is disabled by default
- [ ] Unlock requires threshold review and sign-off

## Exit criteria

- Human-gate-first workflow is operational in pilot
- CI gate chain is enforced on agent-generated PRs
- KPI measurement supports evidence-based unlock decisions
