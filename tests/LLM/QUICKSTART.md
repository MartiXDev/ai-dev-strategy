# LLM Comparison Framework - Quick Start Guide

## 5-Minute Quick Start (Automated CLI Testing)

### Step 1: Verify Prerequisites

```powershell
# PowerShell 7+
$PSVersionTable.PSVersion

# Copilot CLI (primary)
copilot --version

# OR Codex CLI (alternative)
codex --version
```

### Step 2: Navigate to Scripts

```powershell
cd tests/LLM/scripts
```

### Step 3: Run Your First Parallel Test

```powershell
# Test all free models in parallel — fully automated
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "free"
```

When prompted, select a test prompt (press `1` for the CRUD API prompt).

The orchestrator will:

1. Launch up to 8 parallel CLI instances by default (configurable up to 16)
2. Send the prompt to each model simultaneously
3. Capture timing, output, and extract code blocks
4. Run automated quality checks
5. Generate comparison reports
6. Update `Write-Progress` with each benchmark target session state/attempt/PID/elapsed/message details, including separate reasoning variants

The runner enforces that each model outputs all artifacts inside its own model folder (`code\`, `docs\`, `plans\`, `logs\`).

### Step 4: Review Results

```powershell
# Open the Markdown report
code ..\results\<timestamp>\<prompt>\reports\comparison-report.md

# Open run-level totals across all prompts/models
code ..\results\<timestamp>\run-summary.md

# Or the HTML report in browser
start ..\results\<timestamp>\<prompt>\reports\comparison-report.html
```

## Common Commands

```powershell
# All models, all categories, parallel
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all"

# Cheap models only, specific prompt
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "cheap" -TestPromptId "01-crud-api-with-validation"

# Two specific models head-to-head
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-4.1", "claude-haiku-4.5")

# Use Codex CLI instead of Copilot
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -CLIType "codex"

# Benchmark GPT-5.4 reasoning modes via Copilot (separate targets, recorded-only labels)
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "copilot"

# Benchmark GPT-5.4 reasoning modes via Codex (override applied)
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex"

# Compare only selected GPT-5.4 reasoning modes
.\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex" -ReasoningModes @("low", "extra-high")

# Increase parallel slots
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -MaxParallel 8

# Show live CLI output in interactive mode
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -ShowCLIProgress

# Apply specific requirement packs
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -RequirementPacks @("requirements\01-expected-output-structure.md")

# Run strategy-oriented overnight profile
.\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -BenchmarkProfile "overnight-spec-driven"

# Analyze an existing session
.\Invoke-LLMAnalysis.ps1 -SessionPath "..\results\<timestamp>\<prompt>"
```

## Alternative: Manual VS Code Testing

If you prefer testing interactively in VS Code Copilot Chat:

```powershell
.\Invoke-LLMTest.ps1 -LLMCategory "free"
```

This will guide you through switching models manually and recording results.

## Session Output Structure

After a test session, results are organized like this:

```
results/20260216-143000/
├── run-summary.md                 # Totals across all prompts and all LLMs
├── run-summary.json               # Structured run totals for profile comparison
└── 01-crud-api-with-validation/
    ├── session-metadata.json      # Session config snapshot
    ├── prompt-used.md             # The prompt that was sent
    ├── all-results.json           # Consolidated metrics for all models
    ├── gpt-4-1/                   # Per-benchmark-target results
    │   ├── metrics.json           # Timing, cost, quality scores
    │   ├── observations.md        # Auto-generated review template
    │   ├── code/
    │   │   ├── generated-code.cs  # Combined fallback file
    │   │   ├── Program.cs
    │   │   └── ... (other generated *.cs files)
    │   ├── docs/
    │   │   └── ... (generated markdown/docs artifacts)
    │   ├── plans/
    │   │   └── ... (generated plan artifacts)
    │   └── logs/
    │       ├── raw-output.txt     # Full CLI output
    │       ├── stdout.txt         # CLI stdout
    │       ├── stderr.txt         # CLI stderr
    │       ├── instance-events.log
    │       ├── console-transcript.log
    │       └── extracted-artifacts.json
    ├── gpt-5.4-low/               # Per-variant results for reasoning benchmarks
    │   └── ...
    ├── claude-haiku-4-5/
    │   └── ...
    └── reports/                   # Generated per-prompt comparison reports
        ├── comparison-report.md   # Includes one joined table for all categories
        ├── comparison-report.html
        └── comparison-report.json
```

## Performance Benchmarks Guide

| Rating | Duration | Meaning |
|--------|----------|---------|
| Excellent | < 10s | Fast enough for interactive use |
| Good | 10–20s | Acceptable for most workflows |
| Acceptable | 20–30s | Usable but noticeable delay |
| Slow | > 30s | Consider alternatives |

## Quality Score Guide

| Score | Meaning |
|-------|---------|
| 5/5 | Production-ready, all best practices |
| 4/5 | Very good, minor improvements possible |
| 3/5 | Good foundation, some practices missing |
| 2/5 | Functional but needs work |
| 1/5 | Compiles but has major issues |
| 0/5 | Does not compile or severely incomplete |

## Monthly Testing Workflow

```powershell
cd tests/LLM/scripts

# Test all prompts with all models
Get-ChildItem ..\prompts\*.md | ForEach-Object {
    .\Invoke-LLMOrchestrator.ps1 -TestPromptId $_.BaseName -LLMCategory "all"
}
```

## Troubleshooting

```powershell
# Validate config files
Get-Content ..\llm-config.json | ConvertFrom-Json
Get-Content ..\cli-config.json | ConvertFrom-Json

# Check available prompts
Get-ChildItem ..\prompts\*.md | Select-Object Name

# Check for results
Get-ChildItem ..\results -Directory | Select-Object Name

# See script help
Get-Help .\Invoke-LLMOrchestrator.ps1 -Full
Get-Help .\Invoke-CLITest.ps1 -Full
```

Reasoning benchmarks now run as separate benchmark targets on both CLI paths. Result folders use `<model>-<reasoning-mode>` naming whenever a reasoning mode is present. Only Codex currently applies the override automatically; Copilot keeps `reasoningModeApplied = false` and progress/reporting call out that the reasoning label was recorded only.

---

**Full documentation**: See [README.md](README.md)
