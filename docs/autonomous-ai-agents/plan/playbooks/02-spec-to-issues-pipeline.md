# Playbook 02 - Spec to Issues Pipeline

## Objective

Convert specification inputs into routable issues with complete execution data.

## Inputs

- [CONTEXT.md](../../../../CONTEXT.md)
- [Phase 02](../phases/02-spec-to-issues-pipeline.md)
- Pilot scope and acceptance outcomes from Playbook 01

## Preconditions

- Governance gates from Playbook 01 are passed.
- Label families are approved.
- Issue template fields are finalized.

## Procedure

### Cloud-first lane

1. Create issue schema with data sensitivity field.
2. Add cloud budget class and provider eligibility.
3. Add acceptance criteria and test intent per issue.
4. Validate routing metadata completeness.

### Local-first (Lenovo P52) lane

1. Add workload complexity class per issue.
2. Tag heavy tasks for fallback routing.
3. Keep issue granularity small for stable execution.
4. Validate dependencies for serial execution where needed.

### Local-first (Gigabyte) lane

1. Add local capacity profile per issue.
2. Tag issues for parallel batch eligibility.
3. Add model tier recommendation metadata.
4. Validate dependency graph for safe parallelism.

## Decision gates

- Gate G1: Every issue has objective and acceptance criteria.
- Gate G2: Every issue has one primary execution lane.
- Gate G3: Dependency graph has no unresolved cycles.

## Failure modes

- Missing sensitivity data blocks cloud routing.
- Overly large issues reduce routing precision.
- Incorrect dependencies produce blocked queues.

## Rollback

1. Freeze new issue generation.
2. Re-run decomposition with reduced issue scope.
3. Rebuild dependency graph and rerun gate checks.

## Outputs

- Routable issue backlog
- Stable label taxonomy application
- Dependency-safe execution graph

## Owners and SLA

|Role|Responsibility|SLA|
|---|---|---|
|Product owner|Spec decomposition approval|1 business day|
|Platform owner|Label and routing validation|1 business day|
|QA owner|Acceptance/test intent quality|1 business day|

## Evidence checklist

- [ ] Issues include objective and acceptance criteria
- [ ] Issues include test intent and sensitivity class
- [ ] Issues include dependency metadata
- [ ] Each issue maps to one primary execution lane
