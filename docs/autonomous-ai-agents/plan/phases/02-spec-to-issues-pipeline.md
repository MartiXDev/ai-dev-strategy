# Phase 02 - Spec to Issues Pipeline

## Objective

Convert goals into actionable issues with dependencies, labels, and acceptance.

## Scope

- Spec decomposition model (epic -> feature -> story -> task)
- Issue template with mandatory fields
- Label taxonomy and assignment rules
- Variant-aware routing metadata

## Dependencies

- [Phase 01 - Governance and Preparation](./01-governance-and-prep.md)

## Entry criteria

- Governance baseline is approved
- Pilot vertical slice is selected
- Initial label families are agreed

## Activities by strategy variant

### Cloud-first

- Add provider sensitivity tags to issue metadata
- Add cloud budget class per issue
- Add data sensitivity level for gate checks

### Local-first (Lenovo P52)

- Add workload complexity class for constrained routing
- Mark heavy tasks for reroute
- Prefer low-context incremental issue decomposition

### Local-first (Gigabyte)

- Add local capacity profile fields
- Add model tier recommendation metadata
- Prioritize parallelizable tasks for local batch windows

## Deliverables

- Canonical issue schema (`../../control-plane/issue-schema.json`)
- Label taxonomy with ownership and trigger semantics (`../../control-plane/label-taxonomy.json`)
- Dependency encoding rules
- Routing metadata policy per variant

## Weighted decision matrix

|Criterion|Weight|Cloud-first|Local Lenovo|Local Gigabyte|
|---|---|---|---|---|
|Spec clarity|25|High with rich templates|High, compact scope|High, richer scope|
|Routing precision|25|Prevent leakage|Avoid bad loads|Prioritize local value|
|Ops overhead|15|Medium|Medium-high|Medium|
|Cost predictability|20|Needs cost caps|Good for light tasks|Good for wider tasks|
|Throughput potential|15|High with APIs|Limited|High|

## KPI thresholds

|KPI|Threshold for phase completion|
|---|---|
|Template compliance|>= 95% pilot issues use all required fields|
|Label accuracy|>= 90% verified correctness on pilot sample|
|Dependency quality|0 unresolved cyclic dependencies|
|Routing metadata|100% pilot issues include routing fields|

## Mandatory gates checklist

- [ ] Every issue has objective and acceptance criteria
- [ ] Every issue has test intent
- [ ] Every issue has data sensitivity classification
- [ ] Every issue is routable to one primary agent role
- [ ] Every issue has dependency metadata

## Exit criteria

- Pilot backlog is decomposed and routable
- Label taxonomy is stable for orchestration wiring
- Routing metadata supports deterministic decisioning
