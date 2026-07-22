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
4. Route blocked or saturated cloud work to `ready-for-human`.
5. Escalate failures that exceed retry threshold.

### Local-first (Lenovo P52) lane

1. Route only lightweight classes with `minimize-cost` or `balanced` posture to local execution.
2. Reroute blocked or saturated Lenovo work to the Gigabyte lane.
3. Apply low concurrency limits.
4. Escalate repeated saturation to platform owner.

### Local-first (Gigabyte) lane

1. Route standard, heavy, batch, and throughput-priority workloads locally.
2. Accept Lenovo overflow when the fallback policy is triggered.
3. Apply bounded parallel worker pools.
4. Monitor queue depth and timeout trends.
5. Use Cloud-first fallback when capacity threshold is exceeded.

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
