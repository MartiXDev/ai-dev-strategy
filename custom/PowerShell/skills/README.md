# PowerShell Skills

Focused, actionable workflows for transforming **existing** PowerShell code. Each skill is a specialized refactoring tool with step-by-step instructions, examples, and best practices.

**Standard**: Fully compliant with [agentskills.io](https://agentskills.io) open standard.  
**Format**: SKILL.md with YAML frontmatter (name, description, license).  
**Portability**: Works across GitHub Copilot (VS Code, CLI, coding agent) and other skills-compatible agents.

### Storage vs Deployment

**Storage Location** (current): `custom/PowerShell/skills/`
- Central library in ai-dev-strategy repository
- Source of truth for all PowerShell skills
- Updated and maintained centrally

**Deployment Locations** (copy as needed):
- **Project skills**: `.github/skills/powershell/` in your project repository
- **Personal skills**: `~/.copilot/skills/powershell/` for global availability

See [../COMPLIANCE.md](../COMPLIANCE.md) for full deployment guide and standard compliance details.

## Overview

**Skills vs Instructions vs Agent:**

| Aspect | Instructions | Agent | **Skills** |
|--------|--------------|-------|-----------|
| **Activation** | Automatic | Explicit | Explicit |
| **Scope** | Broad conventions | Deep expertise | **Focused task** |
| **Use case** | Writing NEW code | Designing NEW architecture | **Transforming EXISTING code** |
| **Time** | Always-on | 2-5 minutes | **30-60 seconds** |
| **Example** | "Use [CmdletBinding()]" | "Design cloud module" | **"Convert script to module"** |

**All three are complementary, not competing.**

## Available Skills

### 🥇 Critical Priority

#### 1. **powershell-module-builder**
**Purpose**: Convert standalone scripts into proper module structure  
**Use when**: You have working `.ps1` scripts and want to package them as a module  
**What it does**:
- Analyzes existing scripts
- Creates module manifest (`.psd1`)
- Organizes functions into Public/Private folders
- Generates root module (`.psm1`) with import logic
- Validates with `Test-ModuleManifest`

**Example**:
```
Use the powershell-module-builder skill to convert my Get-AzureReport.ps1 and Set-AzureConfig.ps1 into a module
```

[Read full documentation →](powershell-module-builder/SKILL.md)

---

#### 2. **powershell-pester-test-generator**
**Purpose**: Generate comprehensive Pester 5.x tests for existing functions  
**Use when**: Functions lack tests, need safety net before refactoring, TDD retrofit  
**What it does**:
- Analyzes function signature
- Creates test file with BeforeAll, Describe, Context, It blocks
- Generates test cases for:
  - Parameter validation
  - Happy paths
  - Pipeline scenarios
  - Edge cases
  - Error handling

**Example**:
```
Use the powershell-pester-test-generator skill to add tests for my Get-UserReport function
```

[Read full documentation →](powershell-pester-test-generator/SKILL.md)

---

### 🥉 High Priority

#### 3. **powershell-modernizer**
**Purpose**: Upgrade PowerShell 5.1 code to PowerShell 7+ modern syntax  
**Use when**: Migrating from Windows PowerShell 5.1, modernizing legacy scripts  
**What it does**:
- Converts `if/else` → ternary operators (`? :`)
- Converts null checks → null coalescing (`??`, `??=`)
- Converts sequential commands → pipeline chains (`&&`, `||`)
- Adds `ForEach-Object -Parallel` where appropriate
- Fixes cross-platform paths
- Adds `[CmdletBinding()]` if missing

**Example**:
```
Use the powershell-modernizer skill to upgrade this legacy script to PowerShell 7
```

[Read full documentation →](powershell-modernizer/SKILL.md)

---

### 🏅 Medium Priority

#### 4. **powershell-pipeline-support-adder**
**Purpose**: Add pipeline capabilities to existing functions  
**Use when**: Function works but doesn't support pipeline input  
**What it does**:
- Analyzes current function structure
- Adds `ValueFromPipeline` or `ValueFromPipelineByPropertyName`
- Refactors into `begin/process/end` blocks
- Handles both single values and arrays correctly
- Adds pipeline usage examples to help

**Example**:
```
Use the powershell-pipeline-support-adder skill to make my Get-UserData function pipeline-aware
```

[Read full documentation →](powershell-pipeline-support-adder/SKILL.md)

---

#### 5. **powershell-gallery-publisher**
**Purpose**: Prepare and publish modules to PowerShell Gallery  
**Use when**: Ready to publish module publicly or to private gallery  
**What it does**:
- Pre-publication validation checklist
- Validates module manifest
- Runs PSScriptAnalyzer
- Guides API key setup
- Manages version incrementing
- Executes `Publish-Module` with verification

**Example**:
```
Use the powershell-gallery-publisher skill to publish my AzureTools module to PowerShell Gallery
```

[Read full documentation →](powershell-gallery-publisher/SKILL.md)

---

## How to Use Skills

### Option 1: Reference Skill Directly
```
Use the powershell-module-builder skill to convert my scripts into a module
```

### Option 2: Read and Follow Manually
Open the SKILL.md file and follow the step-by-step workflow:
```powershell
Get-Content .\custom\PowerShell\skills\powershell-module-builder\SKILL.md
```

### Option 3: Invoke with Context
```
I have three scripts (Get-Data.ps1, Set-Config.ps1, Remove-Cache.ps1) that I want to package as a module.
Use the powershell-module-builder skill to help me create proper module structure.
```

## Decision Tree: Which Skill?

```
I want to... → What do I need?

Transform existing code:
├─ Scripts → Module → **powershell-module-builder**
├─ No tests → Add tests → **powershell-pester-test-generator**
├─ PS 5.1 → PS 7+ → **powershell-modernizer**
├─ No pipeline → Add pipeline → **powershell-pipeline-support-adder**
└─ Local → Gallery → **powershell-gallery-publisher**

Write new code:
└─ Use PowerShell Instructions (automatic)

Design architecture:
└─ Use PowerShell Expert Agent
```

## Skill Format

Each skill follows a consistent structure:

```markdown
---
name: skill-name
description: Brief description - when to use this skill
---

# Skill Name

## When to Use
Specific scenarios where this skill applies

## Prerequisites
Tools, installations, requirements

## Core Workflow
Step-by-step process with code examples

## Decision Tree
Flowchart for applying transformations

## Examples
Complete before/after examples

## Best Practices
Dos and don'ts

## Reference
Links to related documentation
```

## Skill Development Guidelines

When creating new skills:

1. **Focused scope** - One specific transformation task
2. **Actionable** - Step-by-step instructions, not theory
3. **Examples-driven** - Show before/after code
4. **Self-contained** - No dependencies on other skills
5. **Cross-platform** - Works on Windows, Linux, macOS

## Common Workflows

### Workflow 1: Script → Gallery
```
1. powershell-module-builder → Convert scripts to module
2. powershell-pester-test-generator → Add tests
3. powershell-modernizer → Modernize syntax (if legacy)
4. powershell-gallery-publisher → Publish to PowerShell Gallery
```

### Workflow 2: Legacy Modernization
```
1. powershell-modernizer → Upgrade PS 5.1 → PS 7+
2. powershell-pipeline-support-adder → Add pipeline support
3. powershell-pester-test-generator → Add tests for safety
```

### Workflow 3: Function Enhancement
```
1. powershell-pipeline-support-adder → Add pipeline support
2. powershell-pester-test-generator → Test pipeline scenarios
3. (Optional) powershell-gallery-publisher → Share with community
```

## Frequently Asked Questions

### Q: Should I use a skill or the PowerShell Expert agent?
**A**: Use skills for focused transformations on existing code. Use the agent for designing new modules from scratch.

### Q: Can I combine multiple skills?
**A**: Yes! Skills are designed to be composable. Example: Use `powershell-module-builder` then `powershell-pester-test-generator` then `powershell-gallery-publisher`.

### Q: Do skills modify my code automatically?
**A**: No. Skills provide step-by-step instructions and examples. You execute the changes yourself with full control.

### Q: What if a skill doesn't fit my use case exactly?
**A**: Skills are templates. Adapt the workflow to your specific needs. If you need custom architecture, use the PowerShell Expert agent instead.

### Q: Can I create my own skills?
**A**: Yes! Follow the skill format and add to `custom/PowerShell/skills/`. See existing skills as templates.

## Next Steps

1. **Choose a skill** from the list above based on your needs
2. **Read the full SKILL.md** file for detailed instructions
3. **Follow the workflow** step-by-step with your code
4. **Validate results** with PSScriptAnalyzer and Pester tests
5. **Share feedback** on what worked and what didn't

## Reference

- **Main README**: [../README.md](../README.md) - PowerShell expert system overview
- **Instructions**: [../../.github/instructions/powershell-scripting.instructions.md](../../.github/instructions/powershell-scripting.instructions.md)
- **Agent**: [../../.github/agents/powershell-expert.agent.md](../../.github/agents/powershell-expert.agent.md)
- **Documentation**: [../docs/00-index.md](../docs/00-index.md)
- **Examples**: [../examples/](../examples/)

---

**Quick Reference**:
- 🥇 **powershell-module-builder** - Scripts → Module structure
- 🥇 **powershell-pester-test-generator** - Add Pester 5.x tests
- 🥉 **powershell-modernizer** - PS 5.1 → PS 7+
- 🏅 **powershell-pipeline-support-adder** - Add pipeline support
- 🏅 **powershell-gallery-publisher** - Publish to Gallery

