# AI Agent Execution Playbooks

This folder contains operational playbooks for phase-by-phase execution.

## Dependencies

1. [CONTEXT.md](../../../../CONTEXT.md)
2. [ADR-0001](../../../adr/0001-github-native-orchestration-phase-1.md)
3. [Phase docs](../phases/README.md)

## Playbooks

1. [01-governance-and-prep](./01-governance-and-prep.md)
2. [02-spec-to-issues-pipeline](./02-spec-to-issues-pipeline.md)
3. [03-label-driven-agent-orchestration](./03-label-driven-agent-orchestration.md)
4. [04-ci-cd-testing-pr-flow](./04-ci-cd-testing-pr-flow.md)
5. [05-observability-monitoring-iteration](./05-observability-monitoring-iteration.md)

## Execution lanes in every playbook

- Cloud-first
- Local-first (Lenovo P52)
- Local-first (Gigabyte AI TOP ATOM; abbreviated as Gigabyte)

## Runbook schema

- Objective
- Inputs
- Preconditions
- Procedure
- Decision gates
- Failure modes
- Rollback
- Outputs
- Owners and SLA
- Evidence checklist
