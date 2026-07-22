# Issue Lifecycle Control Plane Contract

This folder defines the baseline control-plane contract for deterministic issue
routing in this repository.

## Artifacts

- `issue-schema.json`: canonical issue schema for routable work items
- `label-taxonomy.json`: triage label taxonomy, routing intent, and transitions
- `routing-policy.json`: deterministic lane selection and fallback policy
- `samples/sample-issue.json`: valid Local-first Lenovo sample issue payload
- `samples/sample-cloud-issue.json`: valid Cloud-first sample issue payload
- `samples/sample-gigabyte-issue.json`: valid Local-first Gigabyte sample issue payload
- `samples/sample-issue-gdpr-blocked.json`: valid cloud-first payload that is blocked by GDPR gate
- `samples/sample-routing-result.json`: successful Local-first Lenovo route output
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
- variant
- routing_profile
- primary_execution_lane
- triage_labels

## Validation and deterministic routing

Use PowerShell 7+ from repository root:

```powershell
Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-issue.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json

Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-cloud-issue.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json

Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-gigabyte-issue.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json
```

Expected output for all four sample issues: `True`.

```powershell
Get-Content .\docs\autonomous-ai-agents\control-plane\samples\sample-issue-gdpr-blocked.json -Raw |
  Test-Json -SchemaFile .\docs\autonomous-ai-agents\control-plane\issue-schema.json
```

Routing intent is deterministic from:

1. `triage_labels[0]` (single canonical triage state)
2. `variant`
3. `routing_profile.workload_class`
4. `routing_profile.hardware_affinity`
5. `routing_profile.cost_posture`
6. `primary_execution_lane` (stored audit result of the deterministic policy)
7. `lane_health` evaluated against `routing-policy.json`
8. `compliance_metadata.gdpr_gate.cloud_eligibility` (cloud gate decision)

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

## Lane selection policy

|Variant|Workload class|Hardware affinity|Cost posture|Primary lane|
|---|---|---|---|---|
|Cloud-first|lightweight / standard / heavy / batch|none|any|cloud-first|
|Local-first|lightweight|lenovo-p52|any|local-first-lenovo-p52|
|Local-first|lightweight / standard / heavy / batch|gigabyte|any|local-first-gigabyte|
|Local-first|lightweight|none|minimize-cost or balanced|local-first-lenovo-p52|
|Local-first|lightweight|none|throughput-priority|local-first-gigabyte|
|Local-first|standard / heavy / batch|none|any|local-first-gigabyte|

Lenovo-constrained workloads always stay on Lenovo and Lenovo remains the
lowest-cost Local-first lane for non-constrained lightweight work.
Gigabyte is the high-capacity Local-first lane for heavier or throughput-oriented
workloads.

## Fallback policy

- Lenovo blocked or saturated -> reroute to Gigabyte
- Gigabyte blocked or saturated -> reroute to Cloud-first when eligible
- Cloud-first blocked or saturated -> route to `ready-for-human`

`samples/sample-fallback-routing-result.json` exercises the saturated Lenovo
scenario and shows the deterministic reroute to Gigabyte.
When GDPR gate fails for cloud-first:

- Cloud route is blocked.
- Deterministic fallback lane is `local-first-gigabyte`.
- Deterministic fallback route is `agent-local-gigabyte-queue`.

For all non-agent triage states (`needs-triage`, `needs-info`,
`ready-for-human`, `wontfix`), routing is non-automated by policy.
