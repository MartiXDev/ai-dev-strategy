# Plugin Index

This repository uses a **plugin-first** strategy: domain guidance is shipped as installable plugins so teams can load only what a task needs (instead of pulling broad, always-on context).

## Install and use with Copilot CLI

```bash
# Install one or more plugins from your configured marketplace
copilot plugin install <plugin-name>@<marketplace-name>
```

Practical workflow:
1. Install the plugin(s) for your task area.
2. Run Copilot on the target task and reference the relevant area (API quality, testing, performance, UI, or release safety).
3. Copilot can use the installed plugin skills to keep guidance focused and consistent.

## Implemented plugins

| Plugin | Directory | Key skill(s) |
| --- | --- | --- |
| `dotnet-api-quality` | [plugins/dotnet-api-quality](./dotnet-api-quality/) | [`dotnet-api-quality`](./dotnet-api-quality/skills/dotnet-api-quality/SKILL.md) |
| `dotnet-testing-quality` | [plugins/dotnet-testing-quality](./dotnet-testing-quality/) | [`tunit-testing-quality`](./dotnet-testing-quality/skills/tunit-testing-quality/SKILL.md) |
| `dotnet-performance` | [plugins/dotnet-performance](./dotnet-performance/) | [`dotnet-performance`](./dotnet-performance/skills/dotnet-performance/SKILL.md) |
| `dotnet-frontend-ui` | [plugins/dotnet-frontend-ui](./dotnet-frontend-ui/) | [`dotnet-frontend-ui`](./dotnet-frontend-ui/skills/dotnet-frontend-ui/SKILL.md) |
| `dotnet-devops-release` | [plugins/dotnet-devops-release](./dotnet-devops-release/) | [`dotnet-devops-release-safety`](./dotnet-devops-release/skills/dotnet-devops-release-safety/SKILL.md) |
