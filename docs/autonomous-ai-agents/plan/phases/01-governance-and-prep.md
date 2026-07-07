# Phase 01 - Governance and Preparation

## Objective

Set operating rules, compliance boundaries, and baseline execution patterns.

## Scope

- Governance model for Cloud-first and Local-first variants
- GDPR cloud-routing gate
- Shared quality and security constraints
- Pilot definition for one low-risk vertical slice

## Dependencies

- None (first phase)

## Entry criteria

- Baseline stack is confirmed: .NET/C#, TypeScript/React, Fluent UI
- Two top-level variants are approved
- Local hardware profiles are confirmed

## Activities by strategy variant

### Cloud-first

- Define approved model providers and region policy
- Define redaction rules before remote inference
- Define API usage caps per agent role

### Local-first (Lenovo P52)

- Restrict to lightweight inference and orchestration
- Route heavy tasks away from Lenovo profile
- Define fallback conditions to cloud or Gigabyte

### Local-first (Gigabyte)

- Define heavy workload classes allowed on-prem
- Define model-serving topology boundaries
- Define throughput and queue policy for batch windows

## Deliverables

- Governance baseline table with ownership
- GDPR gate policy section
- Phase risk taxonomy and mitigations
- Pilot scope definition

## Weighted decision matrix

|Criterion|Weight|Cloud-first|Local Lenovo|Local Gigabyte|
|---|---|---|---|---|
|Privacy control|30|Strong gate needed|Strong, low capacity|Strong, high capacity|
|Speed to pilot|20|Fast API setup|Medium|Medium-high|
|Ops complexity|15|Lower infra|Higher routing load|Higher infra load|
|Unit economics|20|Variable token cost|Low cost, low scale|Low marginal cost|
|Quality ceiling|15|High premium|Lower heavy tasks|High local tiers|

## KPI thresholds

|KPI|Threshold for phase completion|
|---|---|
|Control coverage|100% of required control categories|
|GDPR gate completeness|Redaction + audit trail + DPA path defined|
|Risk coverage|At least one mitigation per high-risk item|
|Pilot definition quality|Scope, acceptance, and rollback are explicit|

## Mandatory gates checklist

- [ ] Cloud data classification policy defined
- [ ] Prompt/input redaction policy defined
- [ ] Audit logging policy defined
- [ ] DPA legal path defined
- [ ] Human-gate-first merge baseline defined

## Exit criteria

- Governance pack is approved and versioned
- Pilot scope is approved and bounded
- Routing policy between cloud and local is explicit
