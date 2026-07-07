---
agent: 'agent'
description: 'Create a bounded architecture plan for one .NET feature slice using scoped context only.'
---
# .NET Architecture Plan (Focused)

Use this prompt to produce an implementation-ready plan (not code) for a single backend feature.

## Inputs

- Goal: `${input:goal}`
- Feature name: `${input:featureName}`
- Path scope: `${input:pathScope}`
- Constraints: `${input:constraints}`
- Existing context: `${selection}`

## Boundaries

- Work only within `${input:pathScope}` and directly related shared files.
- Do not scan unrelated folders or redesign the whole system.
- Keep the plan to one feature slice and one PR-sized change.

## Planning Tasks

1. Summarize the problem and acceptance criteria from the provided context.
2. Propose a vertical-slice file map (endpoint, request/command, handler, validator, response, tests).
3. Define data flow, validation rules, error handling, and security checks.
4. Identify DI registration and configuration changes required.
5. Define minimal tests (unit/integration) and verification commands.
6. Call out risks, assumptions, and any missing inputs.

## Output Format

1. **Scope Summary** (3 bullets max)
2. **Proposed File Changes** (table: file, purpose, create/update)
3. **Implementation Plan** (numbered steps, max 8)
4. **Test Plan** (named tests + command list)
5. **Risks / Open Questions** (only critical items)

