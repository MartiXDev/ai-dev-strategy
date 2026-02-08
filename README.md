# AI Dev Strategy

This repo documents an AI-driven workflow for building modern web apps with .NET 10, C# 14, React 19, Next.js 16, TypeScript 5.x, Fluent UI v9, Griffel CSS-in-JS, and TUnit. The full workflow is in [docs/ai-driven-dotnet-react-workflow.md](docs/ai-driven-dotnet-react-workflow.md).

**Core principles**

- 1 feature = 1 branch = 1 worktree, with multiple tasks per feature.
- Guarded parallelism for `[P]` tasks, with optional task branches for isolation.
- Spec-first: SpecKit `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` during the day.
- Overnight execution: Copilot CLI runs tasks in a dedicated worktree with build/test gates.
- PowerShell-first (Windows 11), with PowerShell 7+ scripts.

**Key components**

- Custom instructions: [.github/instructions/griffel-fluent-ui.instructions.md](.github/instructions/griffel-fluent-ui.instructions.md), [.github/instructions/tunit-testing.instructions.md](.github/instructions/tunit-testing.instructions.md), [.github/instructions/vertical-slice-dotnet.instructions.md](.github/instructions/vertical-slice-dotnet.instructions.md)
- Custom agents: [.github/agents/fullstack-dotnet-react.agent.md](.github/agents/fullstack-dotnet-react.agent.md), [.github/agents/overnight-orchestrator.agent.md](.github/agents/overnight-orchestrator.agent.md)
- Orchestration scripts (PowerShell 7+):
  - [scripts/Invoke-OvernightRun.ps1](scripts/Invoke-OvernightRun.ps1)
  - [scripts/Add-PathHints.ps1](scripts/Add-PathHints.ps1)
  - [scripts/ConvertFrom-TasksFile.ps1](scripts/ConvertFrom-TasksFile.ps1)
  - [scripts/New-MorningReport.ps1](scripts/New-MorningReport.ps1)
  - [scripts/Register-Feature.ps1](scripts/Register-Feature.ps1)
- Configuration: [overnight-config.json](overnight-config.json)
- Collection: [collections/dotnet-react-fullstack.collection.yml](collections/dotnet-react-fullstack.collection.yml)

**Daily workflow (summary)**

1. Create feature spec, plan, and tasks with SpecKit.
2. Tag tasks with categories (BACKEND, FRONTEND, TEST-UNIT, etc.).
3. Register the feature for overnight execution in [overnight-config.json](overnight-config.json).
4. Run [scripts/Invoke-OvernightRun.ps1](scripts/Invoke-OvernightRun.ps1) to implement tasks, run gates, and produce a report.

**Quick start**

```powershell
# Register a feature
.\scripts\Register-Feature.ps1 -SpecDir "specs/001-user-profile" -Branch "feature/001-user-profile"

# Dry run
.\scripts\Invoke-OvernightRun.ps1 -DryRun

# Execute overnight run
.\scripts\Invoke-OvernightRun.ps1
```
