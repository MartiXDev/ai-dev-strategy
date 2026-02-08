---
name: powershell-gallery-publisher
description: Prepare and publish PowerShell modules to PowerShell Gallery with validation, PSScriptAnalyzer, API key management, versioning, and publish workflow. Use this when asked to publish to Gallery, share a module, deploy to PSGallery, make a module public, or distribute PowerShell modules.
license: MIT
---

# PowerShell Gallery Publisher (powershell-gallery-publisher)

Complete workflow for preparing, validating, and publishing PowerShell modules to the PowerShell Gallery (or private galleries).

## When to Use

- Ready to publish module publicly to PowerShell Gallery
- First-time publisher (need end-to-end guidance)
- Want automated pre-publication validation
- Publishing module updates with version management
- Setting up CI/CD for automated publishing

**NOT for**: Internal module distribution (use file shares, private repos, or Azure Artifacts instead).

## Prerequisites

- PowerShell 7+ (or 5.1 with limitations)
- Complete module with manifest (`.psd1`) and code
- PowerShell Gallery account: [Register](https://www.powershellgallery.com/users/account/LogOn)
- API key from PowerShell Gallery (instructions below)
- Module passes basic validation
- Git repository recommended (for versioning and changelog)

## Core Workflow

### Phase 1: Pre-Publication Validation

#### 1. Validate Module Manifest

```powershell
# Test manifest is syntactically correct
Test-ModuleManifest -Path .\MyModule\MyModule.psd1

# If errors, fix them before proceeding
```

**Common manifest issues**:
- Missing required fields (Author, Description, ModuleVersion)
- Incorrect file paths in `RootModule`, `FunctionsToExport`
- Invalid GUID format
- PowerShellVersion compatibility issues

#### 2. Check Required Fields for Gallery

PowerShell Gallery requires specific metadata:

```powershell
# Read current manifest
$manifest = Import-PowerShellDataFile -Path .\MyModule\MyModule.psd1

# Check required fields
$required = @{
    Author = $manifest.Author
    Description = $manifest.Description
    ModuleVersion = $manifest.ModuleVersion
    ProjectUri = $manifest.PrivateData.PSData.ProjectUri
    LicenseUri = $manifest.PrivateData.PSData.LicenseUri
    Tags = $manifest.PrivateData.PSData.Tags
}

# Display missing fields
$required.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object {
    Write-Warning "Missing required field: $($_.Key)"
}
```

**Update manifest if fields are missing**:

```powershell
Update-ModuleManifest -Path .\MyModule\MyModule.psd1 `
    -Author 'Your Name' `
    -Description 'Clear description of what this module does' `
    -ProjectUri 'https://github.com/yourusername/MyModule' `
    -LicenseUri 'https://github.com/yourusername/MyModule/blob/main/LICENSE' `
    -Tags @('Automation', 'Azure', 'DevOps') `
    -ReleaseNotes 'Initial release'
```

**Best practice tags**: Be specific, use popular keywords, max 10 tags.

#### 3. Run PSScriptAnalyzer

Analyze code for best practices violations:

```powershell
# Install PSScriptAnalyzer if needed
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Run analysis
$results = Invoke-ScriptAnalyzer -Path .\MyModule -Recurse -Settings PSGallery

# Display issues
$results | Where-Object Severity -in @('Error', 'Warning') | Format-Table -AutoSize

# MUST fix all errors, SHOULD fix warnings before publishing
```

**Fix common issues**:
- Use approved verbs: `Get-Verb` for list
- Add `[CmdletBinding()]` to all exported functions
- Include comment-based help
- Avoid hardcoded paths
- Use proper error handling

#### 4. Test Module Import

Verify module loads cleanly:

```powershell
# Import in fresh session
$freshSession = New-PSSession
Invoke-Command -Session $freshSession -ScriptBlock {
    Import-Module 'C:\Path\To\MyModule\MyModule.psd1' -Force -ErrorAction Stop
    Get-Command -Module MyModule
}
Remove-PSSession $freshSession

# Check exported functions
$exported = (Get-Module MyModule).ExportedCommands.Keys
Write-Host "Exported $($exported.Count) functions: $($exported -join ', ')"
```

#### 5. Verify README and LICENSE

```powershell
# Check for README
if (-not (Test-Path .\MyModule\README.md)) {
    Write-Warning "README.md not found - strongly recommended"
}

# Check for LICENSE
if (-not (Test-Path .\MyModule\LICENSE)) {
    Write-Warning "LICENSE file not found - required for open source"
}
```

**Recommended README sections**:
- Description
- Installation (`Install-Module -Name MyModule`)
- Usage examples
- Requirements
- Contributing guidelines
- License

### Phase 2: API Key Setup

#### 1. Get API Key from PowerShell Gallery

1. Go to [PowerShell Gallery](https://www.powershellgallery.com/)
2. Sign in with Microsoft account
3. Navigate to: **Account** → **API Keys**
4. Click **Create**
5. Fill in:
   - **Key Name**: "MyModule Publisher" (descriptive name)
   - **Glob Pattern**: `MyModule` (or `*` for all modules)
   - **Expiration**: Set appropriate date (max 1 year)
6. Click **Create**
7. **Copy the API key immediately** (shown only once!)

#### 2. Store API Key Securely

**Option A: Secure String (local development)**

```powershell
# Save encrypted API key (Windows only, current user only)
$apiKey = Read-Host "Enter PowerShell Gallery API Key" -AsSecureString
$apiKey | ConvertFrom-SecureString | Out-File "$env:USERPROFILE\.psgallery-apikey.txt"

# Load when needed
$secureKey = Get-Content "$env:USERPROFILE\.psgallery-apikey.txt" | ConvertTo-SecureString
$apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
)
```

**Option B: Environment Variable (cross-platform)**

```powershell
# Set for current session
$env:PSGalleryApiKey = 'your-api-key-here'

# Permanent (add to profile)
Add-Content $PROFILE "`n# PowerShell Gallery API Key`n`$env:PSGalleryApiKey = 'your-api-key-here'"
```

**Option C: CI/CD Secrets (recommended for automation)**

- GitHub Actions: Store as secret `PSGALLERY_API_KEY`
- Azure DevOps: Store in variable group (secret)
- Jenkins: Use credentials manager

### Phase 3: Version Management

#### 1. Determine New Version

Follow [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features (backwards compatible)
- **Patch** (1.0.0 → 1.0.1): Bug fixes

```powershell
# Get current version
$currentVersion = (Test-ModuleManifest -Path .\MyModule\MyModule.psd1).Version
Write-Host "Current version: $currentVersion"

# Determine new version (example: increment minor)
$newVersion = [version]::new(
    $currentVersion.Major,
    $currentVersion.Minor + 1,
    0  # Reset patch to 0 for minor increment
)
Write-Host "New version: $newVersion"
```

#### 2. Update Manifest Version

```powershell
Update-ModuleManifest -Path .\MyModule\MyModule.psd1 `
    -ModuleVersion $newVersion `
    -ReleaseNotes @"
## Version $newVersion

### Added
- New feature X
- New function Get-Something

### Fixed
- Bug in Set-Something when parameter is null

### Changed
- Improved performance of Get-Data
"@
```

#### 3. Create Git Tag (if using Git)

```powershell
git add .
git commit -m "Release v$newVersion"
git tag -a "v$newVersion" -m "Release version $newVersion"
git push origin main --tags
```

### Phase 4: Publish to Gallery

#### 1. Final Pre-Publish Check

```powershell
# One last manifest validation
Test-ModuleManifest -Path .\MyModule\MyModule.psd1

# One last analyzer check
Invoke-ScriptAnalyzer -Path .\MyModule -Recurse -Severity Error

# Verify version is newer than published version
$galleryVersion = (Find-Module -Name MyModule -ErrorAction SilentlyContinue).Version
if ($galleryVersion -and $newVersion -le $galleryVersion) {
    Write-Error "New version ($newVersion) must be greater than gallery version ($galleryVersion)"
    return
}
```

#### 2. Publish Module

```powershell
# Publish to PowerShell Gallery
Publish-Module -Path .\MyModule -NuGetApiKey $env:PSGalleryApiKey -Verbose -WhatIf

# Review the WhatIf output, then publish for real:
Publish-Module -Path .\MyModule -NuGetApiKey $env:PSGalleryApiKey -Verbose

# For private gallery:
Publish-Module -Path .\MyModule `
    -NuGetApiKey $apiKey `
    -Repository 'MyPrivateGallery' `
    -Verbose
```

**Parameters explained**:
- `-Path`: Path to module folder (not .psd1 file)
- `-NuGetApiKey`: API key from PowerShell Gallery
- `-Repository`: Gallery name (default: PSGallery)
- `-Verbose`: Show detailed progress
- `-WhatIf`: Dry run (test without publishing)

#### 3. Monitor Publish Progress

Publishing is not instantaneous:
1. **Upload**: Module uploaded to gallery (~1-2 minutes)
2. **Scanning**: Automated security scan (~5-10 minutes)
3. **Indexing**: Searchable in gallery (~15-30 minutes)

```powershell
# Wait and verify
Start-Sleep -Seconds 120

# Check if module is discoverable
$published = Find-Module -Name MyModule -RequiredVersion $newVersion -ErrorAction SilentlyContinue
if ($published) {
    Write-Host "✅ Module published successfully!" -ForegroundColor Green
    Write-Host "   Version: $($published.Version)"
    Write-Host "   Published: $($published.PublishedDate)"
    Write-Host "   Install: Install-Module -Name MyModule"
} else {
    Write-Warning "Module not yet indexed (this can take 15-30 minutes)"
}
```

### Phase 5: Post-Publication

#### 1. Verify Installation

Test from clean environment:

```powershell
# Remove local version
Remove-Module MyModule -Force -ErrorAction SilentlyContinue

# Install from gallery
Install-Module -Name MyModule -Force -Scope CurrentUser

# Test functionality
Import-Module MyModule
Get-Command -Module MyModule
# Test key functions
```

#### 2. Update Documentation

- Update README with installation instructions
- Create release notes on GitHub
- Update website/blog with announcement
- Post to social media/forums if appropriate

#### 3. Monitor Gallery Page

Visit: `https://www.powershellgallery.com/packages/MyModule`

Check:
- ✅ Version number correct
- ✅ Description displays properly
- ✅ Tags are correct
- ✅ Links work (ProjectUri, LicenseUri)
- ✅ Installation command correct

## Decision Tree

```
Ready to publish? → Module complete?
    ├─ No → Finish module first
    └─ Yes → Run validation
        → Test-ModuleManifest passes?
            ├─ No → Fix manifest errors
            └─ Yes → Continue
        → PSScriptAnalyzer errors?
            ├─ Yes → Fix errors (required)
            └─ No → Continue
        → Module imports successfully?
            ├─ No → Fix import issues
            └─ Yes → Continue
        → README and LICENSE exist?
            ├─ No → Create them (recommended)
            └─ Yes → Continue

→ Have API key?
    ├─ No → Get from PowerShell Gallery
    └─ Yes → Store securely

→ Version incremented correctly?
    ├─ No → Update manifest version
    └─ Yes → Continue

→ First-time publish?
    ├─ Yes → Use Publish-Module directly
    └─ No → Verify new version > old version

→ Publish-Module succeeds?
    ├─ No → Check errors, fix, retry
    └─ Yes → Wait for indexing, verify installation
```

## Example: Complete Publish Script

```powershell
# complete-publish.ps1
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ModulePath,
    
    [Parameter(Mandatory)]
    [ValidateSet('Major', 'Minor', 'Patch')]
    [string]$VersionIncrement,
    
    [Parameter()]
    [string]$ReleaseNotes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 1. Validate module structure
Write-Host "🔍 Validating module..." -ForegroundColor Cyan
$manifestPath = Join-Path $ModulePath "$((Get-Item $ModulePath).Name).psd1"
if (-not (Test-Path $manifestPath)) {
    throw "Module manifest not found: $manifestPath"
}

$manifest = Test-ModuleManifest -Path $manifestPath
Write-Host "✅ Manifest valid: $($manifest.Name) v$($manifest.Version)" -ForegroundColor Green

# 2. Run PSScriptAnalyzer
Write-Host "`n🔍 Running PSScriptAnalyzer..." -ForegroundColor Cyan
$analysisResults = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Settings PSGallery
$errors = $analysisResults | Where-Object Severity -eq 'Error'
if ($errors) {
    $errors | Format-Table -AutoSize
    throw "PSScriptAnalyzer errors must be fixed before publishing"
}
$warnings = $analysisResults | Where-Object Severity -eq 'Warning'
if ($warnings) {
    Write-Warning "Found $($warnings.Count) warnings (consider fixing)"
}
Write-Host "✅ No errors found" -ForegroundColor Green

# 3. Increment version
Write-Host "`n📦 Incrementing version ($VersionIncrement)..." -ForegroundColor Cyan
$currentVersion = $manifest.Version
$newVersion = switch ($VersionIncrement) {
    'Major' { [version]::new($currentVersion.Major + 1, 0, 0) }
    'Minor' { [version]::new($currentVersion.Major, $currentVersion.Minor + 1, 0) }
    'Patch' { [version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1) }
}
Write-Host "   $currentVersion → $newVersion" -ForegroundColor Yellow

# Update manifest
Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion -ReleaseNotes $ReleaseNotes

# 4. Test import
Write-Host "`n🔍 Testing module import..." -ForegroundColor Cyan
$testSession = New-PSSession
try {
    Invoke-Command -Session $testSession -ScriptBlock {
        param($path)
        Import-Module $path -Force -ErrorAction Stop
    } -ArgumentList $manifestPath
    Write-Host "✅ Module imports successfully" -ForegroundColor Green
}
finally {
    Remove-PSSession $testSession
}

# 5. Load API key
Write-Host "`n🔑 Loading API key..." -ForegroundColor Cyan
if (-not $env:PSGalleryApiKey) {
    $apiKey = Read-Host "Enter PowerShell Gallery API Key" -AsSecureString
    $env:PSGalleryApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
    )
}

# 6. Publish
Write-Host "`n📤 Publishing to PowerShell Gallery..." -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("$($manifest.Name) v$newVersion", "Publish to PowerShell Gallery")) {
    Publish-Module -Path $ModulePath -NuGetApiKey $env:PSGalleryApiKey -Verbose
    
    Write-Host "`n✅ Published successfully!" -ForegroundColor Green
    Write-Host "   Module: $($manifest.Name)" -ForegroundColor White
    Write-Host "   Version: $newVersion" -ForegroundColor White
    Write-Host "   Install: Install-Module -Name $($manifest.Name)" -ForegroundColor White
    
    # 7. Verify
    Write-Host "`n⏳ Waiting for gallery indexing (30 seconds)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
    $published = Find-Module -Name $manifest.Name -RequiredVersion $newVersion -ErrorAction SilentlyContinue
    if ($published) {
        Write-Host "✅ Verified on gallery: https://www.powershellgallery.com/packages/$($manifest.Name)" -ForegroundColor Green
    } else {
        Write-Warning "Not yet indexed (can take 15-30 minutes)"
    }
}
```

**Usage**:
```powershell
.\complete-publish.ps1 -ModulePath .\MyModule -VersionIncrement Minor -ReleaseNotes "Added new features" -WhatIf
.\complete-publish.ps1 -ModulePath .\MyModule -VersionIncrement Minor -ReleaseNotes "Added new features"
```

## Best Practices

### Before Publishing

✅ **DO**:
- Test module in fresh environment
- Run all Pester tests (100% pass)
- Update CHANGELOG.md
- Update README.md with new features
- Increment version following semver
- Add meaningful release notes
- Include LICENSE file
- Add .gitignore (exclude build artifacts)

❌ **DON'T**:
- Publish without testing
- Skip PSScriptAnalyzer
- Publish with hardcoded credentials/paths
- Use version 0.0.1 for production module
- Include test files in published module
- Publish without README

### API Key Security

✅ **DO**:
- Store API keys encrypted or in secure vaults
- Use different keys for different modules (limit scope)
- Set expiration dates on keys
- Revoke keys when no longer needed
- Use CI/CD secrets for automation

❌ **DON'T**:
- Commit API keys to Git
- Share API keys in plain text
- Use wildcard keys for all modules
- Store keys in scripts

### Versioning

Follow semantic versioning strictly:
- **1.0.0** - First stable release
- **1.1.0** - New feature added (backwards compatible)
- **1.1.1** - Bug fix (no new features)
- **2.0.0** - Breaking changes

## Troubleshooting

### Error: "Module not found"
- Wait 15-30 minutes for indexing
- Check gallery webpage directly
- Verify package name matches

### Error: "Version already exists"
- Cannot republish same version
- Increment version and publish again
- Or use `Unlist-PSResource` if needed

### Error: "Invalid API key"
- Regenerate key from gallery
- Check key hasn't expired
- Verify key glob pattern includes module name

### Warning: "PSScriptAnalyzer warnings"
- Fix all errors (required)
- Fix warnings (strongly recommended)
- Use `-ExcludeRule` only if necessary

## Anti-Patterns to Avoid

- ❌ Publishing without version increment
- ❌ Not testing installation from gallery
- ❌ Missing required metadata (ProjectUri, Description)
- ❌ Hardcoded paths in module code
- ❌ Publishing test/example files
- ❌ No README or help documentation
- ❌ Committing API keys to source control
- ❌ Publishing before testing in clean environment

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Publish to PowerShell Gallery

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate Module
        shell: pwsh
        run: |
          Test-ModuleManifest -Path ./MyModule/MyModule.psd1
          Invoke-ScriptAnalyzer -Path ./MyModule -Recurse -Settings PSGallery
      
      - name: Publish Module
        shell: pwsh
        env:
          PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
        run: |
          Publish-Module -Path ./MyModule -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose
```

## Next Steps

1. **Monitor downloads**: Check gallery statistics
2. **Respond to issues**: GitHub issues from users
3. **Plan updates**: Maintain changelog of requested features
4. **Engage community**: Respond to questions, accept PRs
5. **Maintain quality**: Keep tests passing, dependencies updated

## Reference

- PowerShell Gallery: https://www.powershellgallery.com/
- Publish-Module: `Get-Help Publish-Module -Full`
- Module manifest: `Get-Help New-ModuleManifest -Full`
- Best practices: `.github/instructions/powershell-scripting.instructions.md`
- Versioning: https://semver.org/
