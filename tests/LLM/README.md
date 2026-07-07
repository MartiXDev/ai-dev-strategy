# LLM Comparison Testing Framework

A comprehensive PowerShell-based framework for evaluating and comparing Large Language Models (LLMs) available through GitHub Copilot and Codex CLIs. Designed for **automated, parallel testing** — run multiple CLI instances simultaneously and get structured comparison reports.

## Purpose

This framework enables:

- **Automated Parallel Testing** — Run all LLMs simultaneously via CLI orchestration
- **Performance Benchmarking** — Measure response times with millisecond precision
- **Quality Assessment** — Automated + manual code quality checks
- **Cost Analysis** — Track costs for paid/cheap models across all requests
- **Regular Evaluation** — Rerun the full suite when new models are released
- **Informed Decision Making** — Choose the best LLM with data

## Directory Structure

```
tests/LLM/
├── README.md                          # This documentation
├── QUICKSTART.md                      # 5-minute getting started guide
├── llm-config.json                    # LLM model definitions & test settings
├── cli-config.json                    # CLI tool & orchestration settings
├── strategy-profiles.json             # Benchmark profiles (baseline, overnight-spec-driven)
├── external-assets.json               # Catalog of external skills/agent/spec resources
├── OBSERVATIONS-TEMPLATE.md           # Template for manual review notes
├── prompts/                           # Test prompt definitions
│   ├── 01-crud-api-with-validation.md
│   ├── 02-auth-api.md
│   └── 03-realtime-notification-api.md
├── requirements/                      # Reusable prompt requirement packs (*.md)
├── templates/                         # Result/metric templates
│   └── result-entry.json
├── scripts/                           # PowerShell automation scripts
│   ├── Invoke-LLMOrchestrator.ps1    # ★ Main entry point — parallel CLI testing
│   ├── Invoke-CLITest.ps1            # Single-model CLI test runner
│   ├── Invoke-LLMTest.ps1           # Manual VS Code test runner (interactive)
│   └── Invoke-LLMAnalysis.ps1       # Results analysis & report generation
└── results/                           # Test session results (gitignored)
    └── YYYYMMDD-HHMMSS/
        ├── run-summary.md            # Aggregated totals across all prompts and models
        ├── run-summary.json          # Structured run-level summary (for profile comparison)
        └── <prompt-id>/
            ├── session-metadata.json
            ├── prompt-used.md
            ├── all-results.json
            ├── <model-id>[-<reasoning-mode>]/
            │   ├── metrics.json
            │   ├── observations.md
            │   ├── code/
            │   │   ├── generated-code.cs
            │   │   ├── Program.cs
            │   │   └── ... (other generated *.cs files)
            │   ├── docs/
            │   ├── plans/
            │   └── logs/
            │       ├── raw-output.txt
            │       ├── stdout.txt
            │       ├── stderr.txt
            │       ├── instance-events.log
            │       ├── console-transcript.log
            │       └── extracted-artifacts.json
            └── reports/
                ├── comparison-report.md
                ├── comparison-report.html
                └── comparison-report.json
```

## Quick Start

### Prerequisites

- **PowerShell 7.0+** — Required for parallel job support
- **Copilot CLI** — `winget install GitHub.Copilot` (or `brew install copilot-cli` / `npm install -g @github/copilot`)
- **OR Codex CLI** — For Codex-based testing
- **GitHub Copilot subscription** — For model access

### Option A: Automated CLI Orchestration (Recommended)

```powershell
cd tests/LLM/scripts

# Test ALL models in parallel (default: 8 workers)
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all"

# Test only free models
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "free" -CLIType "copilot"

# Test specific models with 6 parallel slots
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-4.1", "claude-haiku-4.5") -MaxParallel 6

# Show live CLI output (interactive mode)
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -ShowCLIProgress

# Use Codex CLI instead
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "cheap" -CLIType "codex"
```

Reports are generated automatically in the session's `reports/` directory.
Each run also generates `results/<timestamp>/run-summary.md` with totals across all prompts and models.

### Option B: Manual VS Code Testing (Interactive)

```powershell
cd tests/LLM/scripts

# Interactive mode — switch models manually in VS Code Copilot Chat
.\Invoke-LLMTest.ps1 -LLMCategory "all"
```

### Option C: Single Model Test

```powershell
# Test one model via CLI directly
.\Invoke-CLITest.ps1 -ModelId "gpt-4.1" -ModelName "GPT-4.1" -Category "free" `
    -PromptText (Get-Content ..\prompts\01-crud-api-with-validation.md -Raw) `
    -OutputDir "..\results\quick-test\gpt-4-1"
```

### Analyze Any Session

```powershell
.\Invoke-LLMAnalysis.ps1 -SessionPath "..\results\YYYYMMDD-HHMMSS\<prompt-id>"
```

## Scripts Reference

### `Invoke-LLMOrchestrator.ps1` — Parallel CLI Testing (Primary)

The main entry point for automated testing. Runs multiple CLI instances in parallel.
Each reasoning-mode benchmark target is scheduled as its own worker/session, so progress and status treat variants such as `gpt-5.4 [low]` and `gpt-5.4 [high]` like separate LLMs.
It now enriches `Write-Progress` with per-session state, attempt, PID, elapsed, and message details sourced from each model's `logs/instance-status.json`. For Copilot reasoning benchmarks, that status also makes it explicit that the reasoning label was recorded but not applied automatically.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-TestPromptId` | string | _(interactive)_ | Prompt file basename (e.g., `01-crud-api-with-validation`) |
| `-LLMCategory` | string | `all` | `free`, `cheap`, `standard`, or `all` |
| `-SpecificModels` | string[] | — | Override category; test these model IDs only |
| `-ReasoningModes` | string[] | _(from config)_ | Optional reasoning-mode override/filter for supported benchmark targets: `low`, `medium`, `high`, `extra-high`. Each selected mode becomes its own benchmark target/session. |
| `-MaxParallel` | int | `8` | Maximum simultaneous CLI instances (range: 1..16) |
| `-CLIType` | string | `copilot` | `copilot` or `codex` |
| `-OutputFormat` | string | `all` | Report format: `markdown`, `json`, or `all` |
| `-BenchmarkProfile` | string | `baseline` | Strategy profile from `strategy-profiles.json` |
| `-RequirementPacks` | string[] | _(auto-discover)_ | Requirement-pack files to append to each prompt contract |
| `-ShowCLIProgress` | switch | off | Show live CLI output in an interactive PowerShell window |

```powershell
# Typical run — all models, CRUD prompt, copilot CLI
.\Invoke-LLMOrchestrator.ps1 -TestPromptId "01-crud-api-with-validation" -LLMCategory "all"

# Cheap models via Codex CLI, 6 parallel
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "cheap" -CLIType "codex" -MaxParallel 6

# Compare configured GPT-5.4 reasoning variants via Copilot (recorded-only labels)
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "copilot"

# Compare configured GPT-5.4 reasoning variants via Codex (override applied)
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex"

# Override the configured reasoning-mode list for GPT-5.4
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex" -ReasoningModes @("low", "high")

# Interactive mode with visible CLI output
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -ShowCLIProgress

# Use specific requirement packs
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -RequirementPacks @("requirements\01-expected-output-structure.md")

# Run overnight strategy benchmark profile
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -BenchmarkProfile "overnight-spec-driven"
```

### `Invoke-CLITest.ps1` — Single Model Test Helper

Runs one test against one model. Called by the orchestrator but can be invoked standalone.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-ModelId` | string | Yes | Model identifier (e.g., `gpt-4.1`) |
| `-ModelName` | string | Yes | Display name |
| `-BaseModelId` | string | No | Underlying CLI model id when the benchmark target is a reasoning-mode variant |
| `-Category` | string | Yes | `free`, `cheap`, or `standard` |
| `-PromptText` | string | Yes | Full prompt text to send |
| `-OutputDir` | string | Yes | Directory for result files |
| `-CLIType` | string | No | `copilot` (default) or `codex` |
| `-CostPerRequest` | decimal | No | USD cost per request (default: 0) |
| `-ReasoningMode` | string | No | User-facing reasoning mode label: `low`, `medium`, `high`, or `extra-high` |
| `-CodexReasoningEffort` | string | No | Explicit Codex effort override, typically auto-derived as `low`, `medium`, `high`, or `xhigh` |
| `-TimeoutSeconds` | int | No | CLI timeout (default: 300) |
| `-ShowCLIProgress` | switch | No | Show live CLI output in an interactive PowerShell window |

**Output files created:**

| File | Description |
|------|-------------|
| `metrics.json` | Structured timing, cost, and quality metrics |
| `code/*.cs` | Extracted C# files (multi-file output target) |
| `code/generated-code.cs` | Combined fallback/compatibility file |
| `docs/*` / `plans/*` | Non-code artifacts from LLM output (design docs, plans, notes) |
| `logs/raw-output.txt` | Complete CLI output |
| `observations.md` | Auto-generated review template |
| `logs/stdout.txt` / `logs/stderr.txt` | Raw CLI streams |
| `logs/extracted-artifacts.json` | List of artifact files extracted from LLM response |

The helper now enforces a strict output contract per model: all generated artifacts (code/docs/plan/etc.) must stay within that model's folder, with C# under `code/`.
For reasoning benchmarks, the folder name is always `<base-model-id>-<reasoning-mode>` and `logs/instance-status.json` + `metrics.json` keep `reasoningModeApplied` honest.
Requirement packs from `tests/LLM/requirements/*.md` are appended automatically unless overridden via `-RequirementPacks`.
When `-BenchmarkProfile` is used, profile-defined requirement packs from `strategy-profiles.json` are applied first.

### `Invoke-LLMTest.ps1` — Manual VS Code Testing

Interactive script for testing via VS Code Copilot Chat. Guides you through switching models, pasting prompts, and recording results manually.

```powershell
.\Invoke-LLMTest.ps1 -LLMCategory "free"
.\Invoke-LLMTest.ps1 -SpecificModel "gpt-4.1"
```

### `Invoke-LLMAnalysis.ps1` — Results Analysis

Generates comparison reports from any completed test session.

```powershell
.\Invoke-LLMAnalysis.ps1 -SessionPath "..\results\<timestamp>\<prompt-id>" -OutputFormat "all"
```

## Configuration

### `llm-config.json` — Model Definitions

Three categories of models with different pricing:

```json
{
  "llmCategories": {
    "free": {
      "description": "Free LLMs — no cost per request",
      "multiplier": 0,
      "models": [
        { "name": "GPT-4.1", "model": "gpt-4.1", "enabled": true }
      ]
    },
    "cheap": {
      "description": "Cheap LLMs — request multiplier < 1x",
      "multiplier": 0.5,
      "models": [
        {
          "name": "Claude Haiku 4.5",
          "model": "claude-haiku-4.5",
          "enabled": true,
          "costPerRequest": 0.0001
        }
      ]
    },
    "standard": {
      "description": "Standard pricing LLMs",
      "multiplier": 1,
      "models": [
        {
          "name": "GPT-5.3-Codex",
          "model": "gpt-5.3-codex",
          "enabled": false,
          "costPerRequest": 0.0005,
          "supportedReasoningModes": ["low", "medium", "high", "extra-high"],
          "defaultReasoningMode": "high",
          "notes": "Disabled historical reference."
        },
        {
          "name": "GPT-5.4",
          "model": "gpt-5.4",
          "enabled": true,
          "costPerRequest": 0.0005,
          "supportedReasoningModes": ["low", "medium", "high", "extra-high"],
          "defaultReasoningMode": "medium",
          "benchmarkReasoningModes": ["low", "medium", "high", "extra-high"],
          "notes": "Active standard benchmark model."
        }
      ]
    }
  },
  "testConfiguration": {
    "maxRetries": 3,
    "timeoutSeconds": 120,
    "warmupRuns": 0,
    "testRuns": 1
  }
}
```

**Adding a new model:**

1. Add an entry to the appropriate category in `llm-config.json`
2. Set `"enabled": true`
3. Set `"costPerRequest"` for paid models
4. Run the orchestrator — the new model is automatically included

**Reasoning-mode fields for supported models:**

- `"supportedReasoningModes"` documents the repository-level user-facing values
- `"defaultReasoningMode"` sets the single-mode default when no benchmark list exists
- `"benchmarkReasoningModes"` expands one base model into multiple benchmark targets for both Copilot and Codex orchestration runs
- Repository value `"extra-high"` maps to official Codex/OpenAI effort value `"xhigh"`

**Important:** current GitHub Copilot CLI automation documents model selection, but not a non-interactive reasoning-effort flag for `copilot --prompt`. The orchestrator still creates separate Copilot benchmark targets per reasoning mode for scheduling/comparison/foldering, but their metadata keeps `reasoningModeApplied = false` and status/reporting calls out that limitation. Codex remains the documented path that actually applies the override automatically.

### `cli-config.json` — CLI & Orchestration Settings

Controls how CLI tools are invoked and how parallelism works:

```json
{
  "cliOptions": {
    "copilot": {
      "command": "copilot",
      "modelFlag": "--model",
      "promptFlag": "--prompt",
      "timeoutSeconds": 300
    },
    "codex": {
      "command": "codex",
      "modelFlag": "--model",
      "promptFlag": "--prompt",
      "timeoutSeconds": 300
    }
  },
  "orchestration": {
    "maxParallelInstances": 5,
    "staggerDelayMs": 500,
    "retryOnFailure": true,
    "maxRetries": 2,
    "retryDelaySeconds": 5
  }
}
```

## Test Prompts

Located in `prompts/`. Each file is a Markdown document with a `## Prompt Text` section that the scripts extract automatically.

### Included Prompts

| ID | Name | Complexity | What It Tests |
|----|------|-----------|---------------|
| `01` | CRUD API with Validation | Medium | Models, DTOs, Controllers, FluentValidation |
| `02` | Auth API | High | JWT, password hashing, security, OWASP practices |
| `03` | Real-time Notification API | High | SignalR hubs, connection management, broadcasting |
| `04` | Spec-Driven Overnight Feature | High | Planning artifacts + task-driven implementation + reusable pattern alignment |

### Creating Custom Prompts

Create a new `.md` file in `prompts/` following this structure:

```markdown
# Test Prompt NN: Title

## Prompt ID
\`NN-short-name\`

## Category
Web API, ...

## Description
What this prompt tests.

## Prompt Text

Generate a C# 14 / .NET 10 Web API that implements...
```

The `## Prompt Text` section content is what gets sent to the LLM.

## Understanding Reports

### Report Sections

1. **Executive Summary** — Model count, avg response time, total cost, fastest/slowest
2. **Detailed Results (All Categories Joined)** — Single ranking table with category column
3. **Code Quality Analysis** — Compilation, best practices, error handling, docs, modern features (0–5)
4. **Strategy Alignment Analysis** — Spec artifacts, structure conformance, reusable pattern alignment
5. **Performance vs Cost** — Free model performance, cheap model cost-efficiency, value ratings
6. **Recommendations** — Best free model, best value cheap model, overall winner

### Quality Scoring (0–5)

Each model receives automated checks for:

| Check | What It Validates |
|-------|-------------------|
| Compilable | Placeholder for manual verification |
| Best Practices | `async Task` + `await` + `ILogger` usage |
| Error Handling | `try/catch`, `ProblemDetails`, `Results.BadRequest`, etc. |
| Documentation | `/// <summary>` or `///` comments |
| Modern Features | `record`, `required`, `init`, primary constructors |

### Cost Efficiency

```
Cost Efficiency = Quality Score / Total Cost
```

Higher values = better value for money.

## Regular Testing Schedule

### Recommended Cadence

| Frequency | Scope | Command |
|-----------|-------|---------|
| After new model release | New model + current favorite | `.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("new-model", "current-best")` |
| Bi-weekly | Free models, prompt 01 | `.\Invoke-LLMOrchestrator.ps1 -LLMCategory "free" -TestPromptId "01-crud-api-with-validation"` |
| Monthly | All models, all prompts | See batch script below |

### Monthly Comprehensive Run

```powershell
cd tests/LLM/scripts

# Run each prompt for all models
$prompts = Get-ChildItem ..\prompts\*.md
foreach ($prompt in $prompts) {
    Write-Host "Testing prompt: $($prompt.BaseName)" -ForegroundColor Cyan
    .\Invoke-LLMOrchestrator.ps1 -TestPromptId $prompt.BaseName -LLMCategory "all"
}

# Generate reports for all sessions from this month
Get-ChildItem ..\results -Directory |
    Where-Object { $_.Name -like "$(Get-Date -Format 'yyyy-MM')*" } |
    ForEach-Object {
        .\Invoke-LLMAnalysis.ps1 -SessionPath $_.FullName
    }
```

### Tracking Changes Over Time

Keep a running log in a markdown file:

```markdown
## 2026-02 — Initial Baseline
- Best Free: GPT-4.1 (12s, Quality: 5/5)
- Best Cheap: Claude Haiku 4.5 ($0.0001, Quality: 5/5)
- Overall Winner: GPT-5.4 [medium]

## 2026-03 — Monthly Review
- Best Free: GPT-5 mini (8s, Quality: 5/5) — improved
- New Model Added: Grok Code Fast 2
```

## Common Workflows

### Find Fastest Free Model

```powershell
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "free" -TestPromptId "01-crud-api-with-validation"
# Review "Best Free Model" in the generated report
```

### Find Best Value for Money

```powershell
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "cheap"
# Review "Cost Efficiency" section
```

### Evaluate a New Model

```powershell
# 1. Add model to llm-config.json
# 2. Test it alongside your current top pick
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("new-model-id", "current-favorite-id")
```

### Benchmark GPT-5.4 Reasoning Modes

```powershell
# Run all configured GPT-5.4 reasoning variants as separate Copilot benchmark targets
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "copilot"

# Run all configured GPT-5.4 reasoning variants with Codex applying the override
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex"

# Compare only low vs extra-high
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex" -ReasoningModes @("low", "extra-high")
```

### Test Across Different Complexities

```powershell
# Simple CRUD
.\Invoke-LLMOrchestrator.ps1 -TestPromptId "01-crud-api-with-validation" -LLMCategory "all"
# Complex security
.\Invoke-LLMOrchestrator.ps1 -TestPromptId "02-auth-api" -LLMCategory "all"
# Real-time systems
.\Invoke-LLMOrchestrator.ps1 -TestPromptId "03-realtime-notification-api" -LLMCategory "all"
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `copilot` not found | Install: `winget install GitHub.Copilot` or `npm install -g @github/copilot` |
| `codex` not found | Install Codex CLI from [openai/codex](https://github.com/openai/codex) |
| PowerShell version error | Install PowerShell 7+: `winget install Microsoft.PowerShell` |
| Invalid JSON config | Validate: `Get-Content ..\llm-config.json \| ConvertFrom-Json` |
| Reasoning mode not applied in Copilot CLI automation | Expected today. Copilot runs still create separate reasoning benchmark targets/folders, but metrics + status keep `reasoningModeApplied = false`. Use `-CLIType "codex"` when you need the override applied automatically. |
| Empty results | Check `all-results.json` exists in prompt session; check `logs\stderr.txt` in model dirs |
| No code extracted | Review `logs\raw-output.txt` — CLI may return non-code-block formats |

## Quick Reference

```powershell
# Full parallel test (all models, all formats)
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all"

# Free models only, specific prompt
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "free" -TestPromptId "01-crud-api-with-validation"

# GPT-5.4 reasoning benchmark via Copilot (recorded-only labels)
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "copilot"

# GPT-5.4 reasoning benchmark via Codex
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex"

# Analyze existing session
.\Invoke-LLMAnalysis.ps1 -SessionPath "..\results\<timestamp>\<prompt-id>"

# Manual interactive test
.\Invoke-LLMTest.ps1 -LLMCategory "free"
```

### File Locations

| What | Path |
|------|------|
| Model config | `llm-config.json` |
| CLI config | `cli-config.json` |
| Strategy profiles | `strategy-profiles.json` |
| External asset catalog | `external-assets.json` |
| Prompts | `prompts/*.md` |
| Requirement packs | `requirements/*.md` |
| Orchestrator | `scripts/Invoke-LLMOrchestrator.ps1` |
| CLI helper | `scripts/Invoke-CLITest.ps1` |
| Manual tester | `scripts/Invoke-LLMTest.ps1` |
| Analyzer | `scripts/Invoke-LLMAnalysis.ps1` |
| Results | `results/<timestamp>/<prompt-id>/` |
| Prompt reports | `results/<timestamp>/<prompt-id>/reports/` |
| Run totals report | `results/<timestamp>/run-summary.md` |
| Run totals JSON | `results/<timestamp>/run-summary.json` |

---

**Last Updated**: March 2026
**Framework Version**: 2.0 — CLI-based parallel orchestration

