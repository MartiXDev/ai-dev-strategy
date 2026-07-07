# Issue Lifecycle Control Plane Contract

This folder defines the baseline control-plane contract for deterministic issue
routing in this repository.

## Artifacts

- `issue-schema.json`: canonical issue schema for routable work items
- `label-taxonomy.json`: triage label taxonomy, routing intent, and transitions
- `samples/sample-issue.json`: valid sample issue payload
- `samples/sample-issue-gdpr-blocked.json`: valid cloud-first payload that is blocked by GDPR gate
- `samples/sample-routing-result.json`: successful cloud route output
- `samples/sample-routing-result-gdpr-blocked.json`: blocked cloud route with deterministic fallback

## Canonical required fields

Every routable issue must include:

- title
- objective
- acceptance_criteria
- test_intent
- data_sensitivity
- compliance_metadata
- dependency_metadata
- primary_execution_lane
- triage_labels

## Validation and deterministic routing

Use PowerShell 7+ from repository root:

```powershell
Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-issue.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json
```

Expected output for both sample issues: `True`.

```powershell
Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-issue-gdpr-blocked.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json
```

Routing intent is deterministic from:

1. `triage_labels[0]` (single canonical triage state)
2. `primary_execution_lane` (execution lane policy)
3. `compliance_metadata.gdpr_gate.cloud_eligibility` (cloud gate decision)

For cloud-first issues, GDPR gate inputs are mandatory before remote execution:

- `data_sensitivity`
- `compliance_metadata.gdpr_gate.redaction_status`
- `compliance_metadata.gdpr_gate.audit_trail_complete`
- `compliance_metadata.gdpr_gate.dpa_eligibility`
- `compliance_metadata.gdpr_gate.cloud_eligibility`

For `ready-for-agent`, lanes map to:

- `cloud-first` -> `agent-cloud-queue`
- `local-first-lenovo-p52` -> `agent-local-lenovo-queue`
- `local-first-gigabyte` -> `agent-local-gigabyte-queue`

When GDPR gate fails for cloud-first:

- Cloud route is blocked.
- Deterministic fallback lane is `local-first-gigabyte`.
- Deterministic fallback route is `agent-local-gigabyte-queue`.

For all non-agent triage states (`needs-triage`, `needs-info`,
`ready-for-human`, `wontfix`), routing is non-automated by policy.
