---
agent: 'agent'
description: 'Perform a high-signal .NET quality review on a scoped set of changes.'
---
# .NET Quality Review (Focused)

Use this prompt to review code quality for a bounded change set and report only meaningful issues.

## Inputs

- Review scope (paths or diff): `${input:reviewScope}`
- PR/change summary: `${input:changeSummary}`
- Standards to enforce: `${input:standards}`
- Selected code/diff context: `${selection}`

## Review Boundaries

- Review only `${input:reviewScope}`.
- Prioritize correctness, security, reliability, and performance.
- Skip style-only comments unless they hide defects.

## Review Checklist

- API/behavior correctness against expected outcomes
- Validation and error-handling gaps
- Security risks (auth, input handling, sensitive data)
- Performance issues (sync-over-async, unnecessary allocations/queries)
- Test coverage gaps for critical paths

## Output Format

1. **Findings** (severity: High/Medium/Low, include `file:line`, impact, fix guidance)
2. **Passed Checks** (brief bullets)
3. **Recommended Next Actions** (max 5, highest priority first)

If no issues are found, return: `No significant quality issues found in scoped changes.`

