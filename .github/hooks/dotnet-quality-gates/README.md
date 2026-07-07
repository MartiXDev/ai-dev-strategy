# dotnet-quality-gates hook pack

Deterministic, non-destructive Copilot hook pack for .NET quality/audit automation.

- `hooks.json`: version `1` hook configuration (`sessionStart`, `userPromptSubmitted`, `sessionEnd`)
- `on-session-start.ps1`: logs session metadata and baseline repo state
- `on-user-prompt.ps1`: logs prompt audit metadata (length/hash/preview)
- `on-session-end.ps1`: logs session end metadata and runs safe quality checks (`dotnet build`, discovered `dotnet test` projects)

Logs are written to: `logs/copilot-hooks/`

- `session-events.jsonl`
- `quality-gates.jsonl`

> Note: Copilot CLI auto-loads `*.json` files directly under `.github/hooks/`.
> If needed, copy or merge this pack's `hooks.json` into a top-level `.github/hooks/*.json` file.
