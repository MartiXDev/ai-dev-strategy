# Phase 03 - Label-driven Agent Orchestration

## Objective

Implement deterministic issue-to-agent execution with bounded retries.

## Scope

- Event flow from labels and issue state changes to execution
- Agent role contracts, preconditions, timeout and retry policy
- Human checkpoints for security or release-sensitive transitions
- Variant-aware routing behavior

## Dependencies

- [Phase 01 - Governance and Preparation](./01-governance-and-prep.md)
- [Phase 02 - Spec to Issues Pipeline](./02-spec-to-issues-pipeline.md)

## Entry criteria

- Label taxonomy is stable
- Pilot issues include routing metadata
- Escalation path is defined

## Activities by strategy variant

### Cloud-first

- Trigger cloud agents only after GDPR gate pass
- Enforce per-agent budget class and request cap
- Route high-risk tasks to stricter human review

### Local-first (Lenovo P52)

- Restrict to lightweight execution classes
- Queue heavy workloads for Gigabyte or cloud fallback
- Keep low concurrency for stable throughput

### Local-first (Gigabyte)

- Enable broader local routing for heavy tasks
- Use bounded parallel worker pools
- Reserve high-capacity windows for batch backlogs

## Deliverables

- Orchestration state model
- Agent contract table
- Timeout and retry policy by label family
- Human checkpoint map by risk level

## Weighted decision matrix

|Criterion|Weight|Cloud-first|Local Lenovo|Local Gigabyte|
|---|---|---|---|---|
|Determinism|25|Strong policy gating|Strong reroute logic|Strong queue control|
|Recoverability|20|Retry with budget cap|Retry with strict fallback|Retry with backoff|
|Compliance safety|20|Pre-inference gate|Local-first + fallback|Local-first + fallback|
|Throughput control|20|API concurrency caps|Low concurrency|Medium-high concurrency|
|Ops simplicity|15|Moderate|Moderate-high|Moderate|

## KPI thresholds

|KPI|Threshold for phase completion|
|---|---|
|Routing success|>= 95% pilot issues routed without manual relabeling|
|Timeout handling|100% timeout paths follow declared policy|
|Retry stability|<= 5% issues exceed max retry count|
|Checkpoint compliance|100% required checkpoints executed|

## Mandatory gates checklist

- [ ] Preconditions and dependency closure are enforced
- [ ] Timeout and retry rules are explicit by label family
- [ ] Security or release labels always require checkpoints
- [ ] Cloud execution is blocked on GDPR gate failure
- [ ] Failure escalation has owner and response SLA

## Exit criteria

- Orchestration is deterministic and auditable on pilot scope
- Failures and retries are bounded and policy-compliant
- Risk-sensitive transitions always pass human checkpoints
