---
agent: 'agent'
description: 'Synchronize .NET documentation with recent scoped changes, without broad doc rewrites.'
---
# .NET Docs Sync (Focused)

Use this prompt to update documentation after implementation changes in a constrained, traceable way.

## Inputs

- Code change scope: `${input:codeScope}`
- Documentation scope: `${input:docsScope}`
- Change summary: `${input:changeSummary}`
- Required audiences: `${input:audience}`
- Existing context/snippets: `${selection}`

## Boundaries

- Update only docs in `${input:docsScope}` that are directly impacted by `${input:codeScope}`.
- Keep edits minimal and avoid unrelated restructuring.
- Prefer updating existing docs over creating new files.

## Sync Tasks

1. Map code changes to impacted docs.
2. Update behavior, contracts, configuration, and usage notes.
3. Ensure examples/commands remain accurate.
4. Highlight backward-incompatible or operationally sensitive changes.

## Output Format

1. **Docs Updated** (file list + what changed)
2. **Traceability Map** (code change -> doc section)
3. **Gaps / Follow-ups** (only unresolved or intentionally deferred items)

