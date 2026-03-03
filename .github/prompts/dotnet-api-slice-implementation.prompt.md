---
agent: 'agent'
description: 'Implement one .NET API vertical slice with minimal, scoped changes and validation.'
---
# .NET API Slice Implementation (Focused)

Use this prompt to implement one backend use case end-to-end in a bounded scope.

## Inputs

- Feature name: `${input:featureName}`
- Slice/use case: `${input:sliceName}`
- Path scope: `${input:pathScope}`
- Acceptance criteria: `${input:acceptanceCriteria}`
- Contract examples (request/response): `${input:apiContract}`
- Existing code context: `${selection}`

## Boundaries

- Modify only files in `${input:pathScope}` plus strictly required shared registration/configuration files.
- Keep changes minimal and limited to this slice.
- Do not refactor unrelated features.

## Implementation Tasks

1. Implement endpoint + slice components (request/command, handler, validator, response).
2. Apply async patterns, input validation, and consistent error responses.
3. Register required services/handlers in DI.
4. Add or update focused tests for the acceptance criteria.
5. Run the smallest relevant build/test commands already used by the repo.

## Output Format

1. **Files Changed** (with one-line reason each)
2. **Behavior Implemented** (mapped to acceptance criteria)
3. **Validation Performed** (commands + result)
4. **Follow-ups** (only if blocking or explicitly out of scope)

