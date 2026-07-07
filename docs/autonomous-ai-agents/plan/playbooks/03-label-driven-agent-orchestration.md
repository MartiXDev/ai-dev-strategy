# Playbook 03 - Label-driven Agent Orchestration

## Objective

Run deterministic issue-to-agent execution with bounded retries and checkpoints.

## Inputs

- [CONTEXT.md](../../../../CONTEXT.md)
- [ADR-0001](../../../adr/0001-github-native-orchestration-phase-1.md)
- [Phase 03](../phases/03-label-driven-agent-orchestration.md)
- Routable backlog from Playbook 02

## Preconditions

- Every issue is label-routable.
- Timeout and retry policy exists by label family.
- Escalation owners and SLA are assigned.

## Procedure

### Cloud-first lane

1. Trigger execution from label events.
2. Enforce GDPR cloud gate before any remote inference.
3. Apply per-agent budget and retry limits.
4. Escalate failures that exceed retry threshold.

### Local-first (Lenovo P52) lane

1. Route only lightweight classes to local execution.
2. Queue heavy tasks for fallback.
3. Apply low concurrency limits.
4. Escalate saturation to platform owner.

### Local-first (Gigabyte) lane

1. Route heavy and batch-eligible tasks locally.
2. Apply bounded parallel worker pools.
3. Monitor queue depth and timeout trends.
4. Use fallback path when capacity threshold is exceeded.

## Decision gates

- Gate G1: Preconditions and dependencies are satisfied.
- Gate G2: Retry policy is enforced for all failures.
- Gate G3: Security and release labels pass human checkpoints.

## Failure modes

- Retry storms from missing backoff policy.
- Silent routing failures from incomplete labels.
- Capacity saturation without fallback handoff.

## Rollback

1. Pause automation for affected label family.
2. Route issues to manual triage queue.
3. Re-enable only after gate compliance is restored.

## Outputs

- Deterministic execution trace
- Bounded failure and retry behavior
- Human-validated transitions for risky work

## Owners and SLA

|Role|Responsibility|SLA|
|---|---|---|
|Platform owner|Routing and retry policy operation|4 hours|
|Security owner|Security checkpoint approval|1 business day|
|Release owner|Release-risk checkpoint approval|1 business day|

## Evidence checklist

- [ ] Every run has traceable input and output metadata
- [ ] Retry count and timeout behavior is recorded
- [ ] Escalations include owner and resolution time
- [ ] Security and release checkpoints are auditable
