# PowerShell Expert Agent Implementation Plan

## Problem Statement

Create a comprehensive AI-powered system for generating and editing top-quality PowerShell 7+ scripts. The system should support:
- Production-quality automation scripts (CI/CD, deployment, tooling)
- PowerShell modules with compiled C# cmdlets
- System administration and management scripts
- Cross-platform PowerShell 7+ development (Windows, Linux, macOS)

## Proposed Approach

**Hybrid Model: Instructions + Agent**

After analyzing the codebase structure and existing patterns, I recommend a **combined approach**:

1. **PowerShell Instructions File** (`.github/instructions/powershell-scripting.instructions.md`)
   - General scripting conventions and best practices
   - Always active when editing `.ps1`, `.psm1`, `.psd1`, `.cs` (for cmdlets)
   - Lightweight, fast, integrated into every PowerShell-related task

2. **PowerShell Expert Agent** (`.github/agents/powershell-expert.agent.md`)
   - Deep cmdlet development knowledge from Microsoft documentation
   - Invoked explicitly for complex tasks (module design, cmdlet creation, advanced patterns)
   - Uses better models (claude-sonnet-4-5 or gpt-5) for quality
   - Access to full toolset for building, testing, publishing

3. **Reference Documentation** (`custom/PowerShell/docs/`)
   - Cached Microsoft Learn pages for offline reference
   - Cmdlet development guidelines
   - Best practices and patterns

## Rationale

**Why not instructions-only?**
- Binary cmdlet development requires deep .NET knowledge beyond simple script patterns
- Instructions files are better for consistent, always-on conventions
- Complex module architecture benefits from agent reasoning

**Why not agent-only?**
- Invoking an agent for every script edit is inefficient
- Basic conventions (param blocks, approved verbs, error handling) should be automatic
- Instructions provide immediate, context-aware guidance

**Why hybrid works best:**
- Instructions handle 80% of daily scripting (conventions, patterns, style)
- Agent handles 20% of complex work (cmdlet design, module architecture, advanced patterns)
- Matches existing pattern: `.instructions.md` files for tech stacks + specialized agents

## Workplan

### Phase 1: Documentation Collection & Analysis
- [X] Fetch Microsoft PowerShell cmdlet development documentation
- [ ] Save all fetched pages to `custom/PowerShell/docs/` as markdown
- [ ] Create index file linking all documentation
- [ ] Extract key concepts for instructions and agent

### Phase 2: PowerShell Instructions File
- [ ] Create `.github/instructions/powershell-scripting.instructions.md`
- [ ] Define file matching patterns (`.ps1`, `.psm1`, `.psd1`, `.cs` for cmdlets)
- [ ] Document PowerShell 7+ scripting conventions:
  - Script structure and organization
  - Parameter blocks with proper validation
  - Error handling (try/catch, ErrorAction, $ErrorActionPreference)
  - Approved verbs (Get-Verb compliance)
  - Pipeline support and `[Parameter(ValueFromPipeline)]`
  - Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
  - Module manifest best practices
  - Cross-platform compatibility (path separators, OS checks)
- [ ] Include anti-patterns to avoid
- [ ] Add testing guidance (Pester 5.x)

### Phase 3: PowerShell Expert Agent
- [ ] Create `.github/agents/powershell-expert.agent.md`
- [ ] Define agent metadata (name, description, model, tools)
- [ ] Incorporate cmdlet development knowledge:
  - Binary cmdlet architecture (Cmdlet vs PSCmdlet base classes)
  - Attribute usage (Cmdlet, Parameter, ValidateSet, etc.)
  - Input processing methods (BeginProcessing, ProcessRecord, EndProcessing)
  - Error reporting (terminating vs non-terminating)
  - ShouldProcess/ShouldContinue for destructive operations
  - Parameter sets and dynamic parameters
  - Pipeline semantics
- [ ] Add module design patterns:
  - Module structure (`.psm1`, `.psd1`, nested modules)
  - Exported functions vs private helpers
  - Module versioning and dependencies
  - PowerShell Gallery publishing
- [ ] Include build and test workflows:
  - dotnet build for binary cmdlets
  - Pester test execution
  - Code signing requirements
  - PSScriptAnalyzer linting

### Phase 4: Integration with Existing Workflow
- [ ] Update `overnight-config.json` to add POWERSHELL category mapping
- [ ] Configure agent for overnight execution (model: gpt-4.1-mini or claude-sonnet)
- [ ] Configure daytime model (gpt-5 or claude-sonnet-4-5)
- [ ] Test instructions file activation with sample .ps1 file
- [ ] Test agent invocation with complex cmdlet task

### Phase 5: Documentation & Examples
- [ ] Create `custom/PowerShell/README.md` with:
  - Overview of the PowerShell expertise system
  - When to rely on instructions vs invoke the agent
  - Quick reference for common patterns
  - Links to Microsoft documentation
- [ ] Add example scripts in `custom/PowerShell/examples/`:
  - Simple script with best practices
  - Module with multiple cmdlets
  - Binary cmdlet in C#
  - Cross-platform script (Windows/Linux/macOS)
  - Pester test examples
- [ ] Create cheat sheet for approved verbs and common patterns

### Phase 6: Validation & Refinement
- [ ] Create test scenarios to validate agent behavior
- [ ] Verify instructions are applied correctly
- [ ] Test overnight execution with POWERSHELL category task
- [ ] Gather feedback and refine content
- [ ] Add to `.github/instructions/` pattern matching if needed

## Key Decisions

### Model Selection
- **Instructions**: N/A (always active, no model)
- **Agent overnight**: `gpt-4.1-mini` (cost-effective for overnight execution)
- **Agent daytime**: `claude-sonnet-4-5` or `gpt-5` (quality for complex cmdlet design)

### File Organization
```
custom/PowerShell/
├── docs/                          # Microsoft Learn documentation cache
│   ├── 00-index.md               # Navigation index
│   ├── cmdlet-overview.md
│   ├── cmdlet-development-guidelines.md
│   ├── approved-verbs.md
│   └── ...
├── examples/                      # Reference implementations
│   ├── basic-script.ps1
│   ├── advanced-module/
│   └── binary-cmdlet/
└── README.md                      # System overview

.github/
├── instructions/
│   └── powershell-scripting.instructions.md   # Auto-applied conventions
└── agents/
    └── powershell-expert.agent.md              # Explicit invocation for complex tasks
```

### Scope Boundaries
- **Instructions cover**: Syntax, conventions, common patterns, style, error handling
- **Agent covers**: Architecture, cmdlet design, module structure, complex scenarios
- **Out of scope**: PowerShell DSC (Desired State Configuration) — can be added later if needed

## Success Criteria

1. Instructions file correctly activates when editing PowerShell files
2. Agent can design and implement a binary cmdlet from requirements
3. Agent can create a PowerShell module with proper manifest
4. Generated scripts follow approved verb naming and conventions
5. Cross-platform compatibility is ensured in generated scripts
6. Integration with overnight-config.json works for POWERSHELL category
7. Documentation is accessible and well-organized

## Future Enhancements

- PowerShell DSC (Desired State Configuration) expertise
- Azure PowerShell module patterns
- AWS Tools for PowerShell patterns
- Advanced debugging techniques
- Performance optimization patterns
- Security best practices (code signing, constrained language mode)
