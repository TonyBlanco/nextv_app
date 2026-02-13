# NeXtv Multi-Repository Skills Installer
# Installs skills from: anthropics, skillcreatorai, obra/superpowers
# Usage: .\install-all-skills.ps1 [-Priority high|medium|all]

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'high', 'medium', 'low')]
    [string]$Priority = 'high'
)

# Colors
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"

# Paths
$SkillsDir = "d:\NEXTV APP\.agent\skills"
$TempDir = Join-Path $SkillsDir "temp_multi_install"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Multi-Repo Skills Installer" -ForegroundColor $InfoColor
Write-Host "========================================" -ForegroundColor $InfoColor
Write-Host "Priority: $Priority" -ForegroundColor $InfoColor
Write-Host "Target: $SkillsDir" -ForegroundColor $InfoColor
Write-Host "========================================`n" -ForegroundColor $InfoColor

# Create temp directory
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir | Out-Null

# Change to skills directory
Set-Location $SkillsDir

$installedCount = 0
$skippedCount = 0
$failedCount = 0

# Function to check if skill already exists
function Test-SkillExists {
    param([string]$SkillName)
    return Test-Path (Join-Path $SkillsDir $SkillName)
}

# Function to install skill
function Install-Skill {
    param(
        [string]$Name,
        [string]$SourcePath,
        [string]$Priority
    )
    
    if (Test-SkillExists $Name) {
        Write-Host "  ⊘ $Name (already installed)" -ForegroundColor $WarningColor
        $script:skippedCount++
        return
    }
    
    Write-Host "  → $Name..." -ForegroundColor $InfoColor
    try {
        if (Test-Path $SourcePath) {
            Copy-Item -Path $SourcePath -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
            $script:installedCount++
        }
        else {
            Write-Host "    ✗ Source not found" -ForegroundColor $WarningColor
            $script:failedCount++
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
        $script:failedCount++
    }
}

# ============================================
# HIGH PRIORITY SKILLS
# ============================================
if ($Priority -eq 'all' -or $Priority -eq 'high') {
    Write-Host "`n[1/4] Installing HIGH PRIORITY Skills..." -ForegroundColor $InfoColor
    Write-Host "Source: obra/superpowers" -ForegroundColor $InfoColor
    
    # Clone obra/superpowers
    git clone --depth 1 --quiet https://github.com/obra/superpowers.git "$TempDir/superpowers" 2>$null
    
    # Debugging Skills
    Install-Skill "systematic-debugging" "$TempDir/superpowers/skills/systematic-debugging" "high"
    Install-Skill "verification-before-completion" "$TempDir/superpowers/skills/verification-before-completion" "high"
    
    # Collaboration Skills
    Install-Skill "brainstorming" "$TempDir/superpowers/skills/brainstorming" "high"
    Install-Skill "writing-plans" "$TempDir/superpowers/skills/writing-plans" "high"
    Install-Skill "executing-plans" "$TempDir/superpowers/skills/executing-plans" "high"
}

# ============================================
# MEDIUM PRIORITY SKILLS
# ============================================
if ($Priority -eq 'all' -or $Priority -eq 'medium') {
    Write-Host "`n[2/4] Installing MEDIUM PRIORITY Skills..." -ForegroundColor $InfoColor
    Write-Host "Source: skillcreatorai/Ai-Agent-Skills" -ForegroundColor $InfoColor
    
    # Clone skillcreatorai
    git clone --depth 1 --quiet https://github.com/skillcreatorai/Ai-Agent-Skills.git "$TempDir/ai-agent-skills" 2>$null
    
    # Development Skills
    Install-Skill "code-review" "$TempDir/ai-agent-skills/skills/code-review" "medium"
    Install-Skill "code-refactoring" "$TempDir/ai-agent-skills/skills/code-refactoring" "medium"
    Install-Skill "database-design" "$TempDir/ai-agent-skills/skills/database-design" "medium"
    Install-Skill "code-documentation" "$TempDir/ai-agent-skills/skills/code-documentation" "medium"
    
    # More obra/superpowers skills
    if (-not (Test-Path "$TempDir/superpowers")) {
        git clone --depth 1 --quiet https://github.com/obra/superpowers.git "$TempDir/superpowers" 2>$null
    }
    
    Install-Skill "dispatching-parallel-agents" "$TempDir/superpowers/skills/dispatching-parallel-agents" "medium"
    Install-Skill "requesting-code-review" "$TempDir/superpowers/skills/requesting-code-review" "medium"
    Install-Skill "receiving-code-review" "$TempDir/superpowers/skills/receiving-code-review" "medium"
    Install-Skill "finishing-a-development-branch" "$TempDir/superpowers/skills/finishing-a-development-branch" "medium"
}

# ============================================
# LOW PRIORITY SKILLS
# ============================================
if ($Priority -eq 'all' -or $Priority -eq 'low') {
    Write-Host "`n[3/4] Installing LOW PRIORITY Skills..." -ForegroundColor $InfoColor
    
    # Productivity Skills from skillcreatorai
    if (-not (Test-Path "$TempDir/ai-agent-skills")) {
        git clone --depth 1 --quiet https://github.com/skillcreatorai/Ai-Agent-Skills.git "$TempDir/ai-agent-skills" 2>$null
    }
    
    Install-Skill "ask-questions-if-underspecified" "$TempDir/ai-agent-skills/skills/ask-questions-if-underspecified" "low"
    Install-Skill "qa-regression" "$TempDir/ai-agent-skills/skills/qa-regression" "low"
    
    # Meta Skills from obra/superpowers
    if (-not (Test-Path "$TempDir/superpowers")) {
        git clone --depth 1 --quiet https://github.com/obra/superpowers.git "$TempDir/superpowers" 2>$null
    }
    
    Install-Skill "writing-skills" "$TempDir/superpowers/skills/writing-skills" "low"
    Install-Skill "using-superpowers" "$TempDir/superpowers/skills/using-superpowers" "low"
}

# ============================================
# CLEANUP
# ============================================
Write-Host "`n[4/4] Cleaning up..." -ForegroundColor $InfoColor
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n========================================" -ForegroundColor $SuccessColor
Write-Host "  Installation Summary" -ForegroundColor $SuccessColor
Write-Host "========================================" -ForegroundColor $SuccessColor

$totalSkills = (Get-ChildItem $SkillsDir -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName "SKILL.md")) -or 
        (Test-Path (Join-Path $_.FullName "CLAUDE.md"))
    }).Count

Write-Host "✓ Installed: $installedCount" -ForegroundColor $SuccessColor
Write-Host "⊘ Skipped: $skippedCount (already exist)" -ForegroundColor $WarningColor
Write-Host "✗ Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { $ErrorColor } else { $SuccessColor })
Write-Host "Total Skills: $totalSkills" -ForegroundColor $InfoColor

# List newly installed skills
if ($installedCount -gt 0) {
    Write-Host "`nNewly Installed Skills:" -ForegroundColor $InfoColor
    
    $newSkills = @(
        'systematic-debugging', 'verification-before-completion',
        'brainstorming', 'writing-plans', 'executing-plans',
        'code-review', 'code-refactoring', 'database-design', 'code-documentation',
        'dispatching-parallel-agents', 'requesting-code-review', 'receiving-code-review',
        'finishing-a-development-branch', 'ask-questions-if-underspecified',
        'qa-regression', 'writing-skills', 'using-superpowers'
    )
    
    foreach ($skill in $newSkills) {
        if (Test-Path (Join-Path $SkillsDir $skill)) {
            Write-Host "  ✓ $skill" -ForegroundColor $SuccessColor
        }
    }
}

Write-Host "`n========================================`n" -ForegroundColor $SuccessColor

if ($installedCount -gt 0) {
    Write-Host "Installation complete! Restart Claude to use new skills." -ForegroundColor $InfoColor
}
else {
    Write-Host "No new skills installed. All recommended skills already present." -ForegroundColor $InfoColor
}
