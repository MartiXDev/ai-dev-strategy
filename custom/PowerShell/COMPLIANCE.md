# Agent Skills Compliance

**PowerShell Skills Compliance with [agentskills.io](https://agentskills.io) Standard**

---

## Compliance Status: ✅ 100% Format Compliant

Our PowerShell skills fully comply with the official Agent Skills standard specification.

### ✅ Format Compliance

| Requirement | Status | Details |
|-------------|--------|---------|
| **SKILL.md filename** | ✅ Pass | All skills use `SKILL.md` |
| **YAML frontmatter** | ✅ Pass | All skills have proper frontmatter |
| **`name` field** | ✅ Pass | Lowercase with hyphens, max 64 chars |
| **`description` field** | ✅ Pass | What + when to use, max 1024 chars |
| **`license` field** | ✅ Pass | MIT license specified |
| **Markdown body** | ✅ Pass | Clear instructions, examples, workflows |
| **Skill isolation** | ✅ Pass | Each skill in own directory |

### 📊 Skill Metadata

| Skill | Name Length | Description Length | Compliant |
|-------|-------------|-------------------|-----------|
| powershell-module-builder | 25 chars | 290 chars | ✅ |
| powershell-pester-test-generator | 32 chars | 304 chars | ✅ |
| powershell-modernizer | 21 chars | 292 chars | ✅ |
| powershell-pipeline-support-adder | 33 chars | 326 chars | ✅ |
| powershell-gallery-publisher | 28 chars | 279 chars | ✅ |

**All within limits**: name ≤ 64 chars, description ≤ 1024 chars

---

## Deployment Strategy

### Why `custom/PowerShell/skills/` Instead of `.github/skills/`?

**Centralized Library Approach**:

- Skills stored in **central repository** (`ai-dev-strategy`)
- **Manual deployment** to project-specific locations
- Allows **selective skill installation** (copy only what's needed)
- Avoids **cluttering every project** with all skills

### Official Standard Locations

For reference, the Agent Skills standard specifies:

**Project skills**: `.github/skills/` (recommended) or `.claude/skills/` (legacy)  
**Personal skills**: `~/.copilot/skills/` (recommended) or `~/.claude/skills/` (legacy)

### Deployment Workflow

**Option 1: Copy to Project Repository**

When you need PowerShell skills in a specific project:

```powershell
# Navigate to your project
cd C:\MyProject

# Copy specific skill(s)
New-Item -Path ".github\skills\powershell" -ItemType Directory -Force
Copy-Item -Path "C:\Git\MartiXDev\ai-dev-strategy\custom\PowerShell\skills\powershell-module-builder" `
          -Destination ".github\skills\powershell\powershell-module-builder" `
          -Recurse

# Or copy all skills
Copy-Item -Path "C:\Git\MartiXDev\ai-dev-strategy\custom\PowerShell\skills\*" `
          -Destination ".github\skills\powershell\" `
          -Recurse
```

**Option 2: Copy to Personal Skills Folder**

For global availability across all projects:

```powershell
# Copy to personal skills folder
$personalSkills = Join-Path $HOME ".copilot\skills\powershell"
New-Item -Path $personalSkills -ItemType Directory -Force

Copy-Item -Path "C:\Git\MartiXDev\ai-dev-strategy\custom\PowerShell\skills\*" `
          -Destination $personalSkills `
          -Recurse
```

**Option 3: Symlink (Advanced)**

For always-current skills without copying:

```powershell
# Create symbolic link (requires admin)
New-Item -ItemType SymbolicLink `
         -Path ".github\skills\powershell" `
         -Target "C:\Git\MartiXDev\ai-dev-strategy\custom\PowerShell\skills"
```

---

## Progressive Disclosure Pattern

Our skills follow the official 3-level progressive disclosure pattern:

**Level 1: Discovery (Always Loaded)**

- YAML frontmatter (`name`, `description`, `license`)
- Lightweight metadata for skill matching
- ~100 bytes per skill

**Level 2: Instructions (Loaded When Relevant)**

- SKILL.md body (full instructions, workflows, examples)
- Loaded only when skill description matches user request
- ~10-20 KB per skill

**Level 3: Resources (Loaded On-Demand)**

- Additional files referenced in SKILL.md
- *(Future enhancement: add examples/, templates/, scripts/)*
- Loaded only when Copilot accesses them

**Benefit**: Can install many skills without context pollution. Only relevant content loads.

---

## Portability

These skills work across multiple Agent Skills-compatible tools:

| Tool | Compatibility | Notes |
|------|---------------|-------|
| **GitHub Copilot (VS Code)** | ✅ Full | Auto-discovers from `.github/skills/` |
| **GitHub Copilot CLI** | ✅ Full | Uses same skill format |
| **GitHub Copilot Coding Agent** | ✅ Full | Background automation mode |
| **Claude Code (Anthropic)** | ✅ Full | Legacy location: `.claude/skills/` |
| **Other skills-compatible agents** | ✅ Expected | Open standard |

---

## Validation

To verify skills are discovered:

**VS Code**:

1. Copy skills to `.github/skills/powershell/` in your project
2. Open VS Code Copilot Chat
3. Type: `@workspace /help`
4. Check if skills are listed

**Copilot CLI**:

```bash
# In project with skills
gh copilot suggest "create a PowerShell module"
# Should auto-load powershell-module-builder skill
```

**Manual verification**:

```powershell
# Check SKILL.md format
Get-Content ".github\skills\powershell\powershell-module-builder\SKILL.md" -Head 10

# Should show YAML frontmatter:
# ---
# name: powershell-module-builder
# description: ...
# license: MIT
# ---
```

---

## Compliance Checklist

Use this checklist when creating new skills:

### Required Fields

- [ ] `SKILL.md` file exists
- [ ] YAML frontmatter present
- [ ] `name` field (lowercase-with-hyphens, max 64 chars)
- [ ] `description` field (what + when, max 1024 chars)
- [ ] `license` field (MIT)

### Content Quality

- [ ] Clear "When to Use" section
- [ ] Step-by-step workflow or procedures
- [ ] Examples with input/output
- [ ] Best practices / anti-patterns
- [ ] References to resources (if any)

### Naming Conventions

- [ ] Skill name: lowercase with hyphens
- [ ] Directory name matches skill name
- [ ] No spaces or special characters

### Description Optimization

- [ ] Explains **what** the skill does
- [ ] Explains **when** to use it
- [ ] Includes trigger phrases users might say
- [ ] Under 1024 characters

### Testing

- [ ] YAML frontmatter parses correctly
- [ ] Description accurately describes capability
- [ ] Instructions are clear and actionable
- [ ] Examples work as written

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.1 | 2026-02-08 | Added compliance with agentskills.io standard |
| | | - Updated descriptions with trigger phrases |
| | | - Added `license: MIT` to all skills |
| | | - Created COMPLIANCE.md |
| 1.0 | 2026-02-08 | Initial PowerShell skills release |
| | | - 5 skills created |
| | | - SKILL.md format established |

---

## References

- **Official Specification**: [agentskills.io](https://agentskills.io)
- **VS Code Documentation**: [Agent Skills Guide](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- **Reference Skills**: [anthropics/skills](https://github.com/anthropics/skills)
- **Community Skills**: [github/awesome-copilot](https://github.com/github/awesome-copilot)

---

## Future Enhancements

Potential improvements to increase compliance and usability:

### Progressive Disclosure Resources (Level 3)

Add resource files to skill directories:

```
powershell-module-builder/
├── SKILL.md
├── examples/
│   └── complete-module/        # Full working example
├── templates/
│   └── module-manifest.psd1    # Reusable template
└── scripts/
    └── scaffold.ps1            # Helper automation
```

### Concise Skill Format

Refactor skills to match reference pattern:

- **SKILL.md**: Concise guide (~3 KB)
- **examples/**: Verbose references
- **templates/**: Copy-paste starting points

### Automation Scripts

Add helper scripts for common workflows:

- `create-module-scaffold.ps1` (powershell-module-builder)
- `generate-test-file.ps1` (powershell-pester-test-generator)
- `modernize-script.ps1` (powershell-modernizer)

---

## License

All PowerShell skills are licensed under **MIT License**, matching the ai-dev-strategy repository license.

---

**Maintained by**: ai-dev-strategy repository  
**Last Updated**: 2026-02-08  
**Compliance Version**: agentskills.io v1.0
