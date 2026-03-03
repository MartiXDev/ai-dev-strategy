# .NET Testing Quality Plugin

TUnit-first testing quality package for .NET teams, with explicit integration-test fallback guidance, naming patterns, and reliability gates for CI.

## Installation

```bash
# Using Copilot CLI
copilot plugin install dotnet-testing-quality@martixdev
```

## What's Included

### Skills

| Skill | Description |
|-------|-------------|
| `tunit-testing-quality` | Applies a TUnit-first workflow for unit/component tests, defines integration-test fallback rules, enforces naming standards, and uses reliability gates before merge. |

## Focus Areas

- **TUnit-first** for unit and component tests, async assertions, and parallel-safe patterns.
- **Integration fallback** to xUnit only when required (for example `WebApplicationFactory` scenarios not covered by TUnit in your stack).
- **Naming patterns** to keep tests self-documenting and maintainable.
- **Reliability gates** to prevent flaky or partial test quality from reaching main.

## Source

This plugin is maintained in the `ai-dev-strategy` repository.

## License

MIT
