---
name: dotnet-devops-release-safety
description: 'Enforce .NET release safety with CI build/test gates, deployment preflight checks, and rollback-ready delivery discipline.'
---

# .NET DevOps Release Safety

Use this skill to harden .NET CI/CD releases before production exposure.

## Release Gate Workflow

### 1) Build and Artifact Integrity Gate

- Restore dependencies from trusted feeds and build in `Release` configuration.
- Fail on build warnings promoted to errors for release branches.
- Publish immutable, versioned artifacts and retain checksum evidence.

### 2) Test and Quality Gate

- Require green unit/integration suites and no failures in critical smoke tests.
- Block release when flaky tests are unresolved or critical suites are skipped.
- Enforce non-regression guardrails for quality signals (for example: coverage trend, static analysis severity, or mutation score where configured).

### 3) Deployment Preflight Gate

- Validate environment-specific configuration, secrets references, and feature-flag defaults.
- Confirm database migration strategy is safe (forward and recovery approach documented).
- Verify readiness/liveness probe endpoints and dependency connectivity checks.

### 4) Controlled Deployment Gate

- Prefer progressive rollout (canary/ring/blue-green) over all-at-once production cutovers.
- Define measurable promotion criteria (error rate, latency, saturation, and business KPIs).
- Require explicit approval checkpoints between rollout stages.

### 5) Rollback Readiness Gate

- Keep last-known-good artifact immediately deployable.
- Define clear rollback trigger thresholds and ownership.
- Validate rollback runbook steps, communication channel, and execution command before go-live.

### 6) Post-Deploy Verification Gate

- Run production smoke checks and confirm SLO/SLA health.
- Capture release evidence: gate outcomes, deployment metadata, and incident references.
- Open follow-up actions for any degraded but accepted signals.

## Definition of Done

- All release gates pass with traceable evidence.
- Deployment was verified against defined health and performance criteria.
- Rollback plan is executable without additional preparation.
