# AI Agent Delivery Context

This context defines canonical planning language for the AI agent delivery
program in this repository.

## Language

**Variant**:
A top-level strategy option for delivery architecture.
_Avoid_: Approach, mode

**Cloud-first**:
A variant where default execution uses cloud-hosted models.
_Avoid_: Remote-only

**Local-first**:
A variant where default execution uses locally hosted models.
_Avoid_: On-device-only

**Execution lane**:
A concrete operating path inside one phase for one variant profile.
_Avoid_: Track, swimlane

**Gate**:
A mandatory decision checkpoint that must pass before progression.
_Avoid_: Soft check, suggestion

**Threshold**:
A measurable numeric condition used to unlock or block progression.
_Avoid_: Target, aspiration

**Fallback**:
The predefined reroute path when primary execution cannot proceed safely.
_Avoid_: Workaround, ad hoc reroute

**Pilot slice**:
One bounded low-risk vertical feature used for end-to-end validation.
_Avoid_: Sample, demo

**Human-gate merge**:
A merge policy requiring explicit human approval before merge.
_Avoid_: Assisted merge

**Selective auto-merge**:
A merge policy that allows automation only for approved low-risk classes.
_Avoid_: Full auto-merge
