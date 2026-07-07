# Phase 05 - Observability, Monitoring, and Iteration

## Objective

Run the system with measurable reliability, compliance, and cost control.
Improve policy and routing from evidence on a fixed cadence.

## Scope

- Telemetry model for orchestration, quality, cost, and compliance
- Monitoring cadence and alert thresholds
- Optimization loop for prompts, skills, routing, and gates
- Variant-specific operational tuning

## Dependencies

- [Phase 04 - CI/CD, Testing, and PR Flow](./04-ci-cd-testing-pr-flow.md)

## Entry criteria

- CI/CD and PR gate model is operational
- Merge baseline policy is enforced
- Instrumentation points are identified

## Activities by strategy variant

### Cloud-first

- Monitor token usage, provider latency, and budget breaches
- Track GDPR gate pass and fail counts
- Tune model-tier routing for quality and cost balance

### Local-first (Lenovo P52)

- Monitor queue latency and local saturation
- Track fallback frequency to cloud or Gigabyte
- Tune issue granularity for constrained throughput

### Local-first (Gigabyte)

- Monitor throughput, queue depth, and hardware utilization
- Tune worker limits for stable latency and cost
- Optimize batch windows for non-urgent workloads

## Deliverables

- KPI dashboard definition
- Alert catalog with owners and response targets
- Monthly optimization review template
- Policy update workflow with rollback rules

## Weighted decision matrix

- **Measurement completeness (25)**
  - Cloud-first: strong provider metrics
  - Local Lenovo: strong fallback metrics
  - Local Gigabyte: strong capacity metrics
- **Cost control (25)**
  - Cloud-first: budget and routing tuning
  - Local Lenovo: lower cost, slower throughput
  - Local Gigabyte: efficient at scale
- **Reliability (20)**
  - Cloud-first: provider and retry stability
  - Local Lenovo: sensitive to hardware limits
  - Local Gigabyte: high after tuning
- **Compliance evidence (20)**
  - Cloud-first: prove cloud gate enforcement
  - Local Lenovo: local-first plus fallback gate
  - Local Gigabyte: local-first plus fallback gate
- **Improvement velocity (10)**
  - Cloud-first: high
  - Local Lenovo: medium
  - Local Gigabyte: medium-high

## KPI thresholds

|KPI|Steady-state threshold|
|---|---|
|Issue-to-merge lead time|<= baseline + 10% with quality gains|
|Routing policy adherence|>= 98%|
|GDPR cloud gate violations|0|
|Cost variance vs monthly budget|<= 10%|
|Reopened issues from quality gaps|<= 5%|
|Critical orchestration alert MTTR|<= 4 hours|

## Mandatory gates checklist

- [ ] Lifecycle events are traceable from issue to merge
- [ ] Compliance and routing violations alert immediately
- [ ] Monthly threshold review is executed and recorded
- [ ] Policy changes include rollback path and owner sign-off
- [ ] Auto-merge policy remains threshold-gated

## Exit criteria

- Dashboard and alerts are active and owned
- Improvement loop runs on a fixed cadence
- Policy and routing changes are data-backed and reversible
