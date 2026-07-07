# Playbook 01 - Governance and Preparation

## Objective

Operationalize governance, compliance, and baseline controls before agent work.

## Inputs

- [CONTEXT.md](../../../../CONTEXT.md)
- [ADR-0001](../../../adr/0001-github-native-orchestration-phase-1.md)
- [Phase 01](../phases/01-governance-and-prep.md)

## Preconditions

- Variant and execution lane terminology is approved.
- GDPR gate policy exists and has owners.
- Human-gate merge policy is set as default.

## Procedure

### Cloud-first lane

1. Approve cloud providers and allowed regions.
2. Define redaction rules for prompts and context.
3. Define audit trail fields for every model call.
4. Define DPA validation path and approval owner.

### Local-first (Lenovo P52) lane

1. Define allowed workload classes for constrained hardware.
2. Define fallback to cloud or Gigabyte for heavy tasks.
3. Set conservative concurrency limits.
4. Document queue and escalation behavior.

### Local-first (Gigabyte) lane

1. Define allowed heavy workload classes.
2. Define local serving boundaries and isolation.
3. Set initial batch window and worker limits.
4. Document fallback path when local capacity is saturated.

## Decision gates

- Gate G1: GDPR cloud gate is complete.
- Gate G2: Governance ownership matrix is approved.
- Gate G3: Pilot slice scope is bounded and signed off.

## Failure modes

- Undefined data classification blocks cloud execution.
- No fallback path causes queue deadlocks.
- Missing ownership causes unresolved gate decisions.

## Rollback

1. Stop cloud routing for sensitive workloads.
2. Route all tasks through human triage only.
3. Re-run governance approval with updated owners.

## Outputs

- Approved governance baseline
- Approved GDPR cloud gate policy
- Approved pilot slice boundary

## Owners and SLA

|Role|Responsibility|SLA|
|---|---|---|
|Compliance owner|GDPR gate approval|1 business day|
|Platform owner|Routing and fallback policy|1 business day|
|Engineering lead|Pilot scope sign-off|1 business day|

## Evidence checklist

- [ ] Provider and region policy is documented
- [ ] Redaction and audit trail fields are documented
- [ ] DPA path has named owner
- [ ] Pilot slice has explicit scope and exclusions
