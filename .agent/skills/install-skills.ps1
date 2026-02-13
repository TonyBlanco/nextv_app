# NeXtv Skills Auto-Installer
# Installs recommended Claude skills for Flutter IPTV development
# Usage: .\install-skills.ps1

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'high', 'medium')]
    [string]$Priority = 'high'
)

# Colors
$InfoColor = "Cyan"
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"

# Paths
$SkillsDir = "d:\NEXTV APP\.agent\skills"
$TempDir = Join-Path $SkillsDir "temp_install"

Write-Host "`n========================================" -ForegroundColor $InfoColor
Write-Host "  NeXtv Skills Installer" -ForegroundColor $InfoColor
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

# High Priority Skills
if ($Priority -eq 'all' -or $Priority -eq 'high') {
    Write-Host "[1/3] Installing High Priority Skills..." -ForegroundColor $InfoColor
    
    # Software Architecture
    Write-Host "  → software-architecture..." -ForegroundColor $InfoColor
    try {
        git clone --depth 1 --quiet https://github.com/NeoLabHQ/context-engineering-kit.git $TempDir/context-kit 2>$null
        if (Test-Path "$TempDir/context-kit/plugins/ddd/skills/software-architecture") {
            Copy-Item -Path "$TempDir/context-kit/plugins/ddd/skills/software-architecture" -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
        }
        else {
            Write-Host "    ✗ Not found in repo" -ForegroundColor $WarningColor
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
    
    # Test-Driven Development
    Write-Host "  → test-driven-development..." -ForegroundColor $InfoColor
    try {
        git clone --depth 1 --quiet https://github.com/obra/superpowers.git $TempDir/superpowers 2>$null
        if (Test-Path "$TempDir/superpowers/skills/test-driven-development") {
            Copy-Item -Path "$TempDir/superpowers/skills/test-driven-development" -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
        }
        else {
            Write-Host "    ✗ Not found in repo" -ForegroundColor $WarningColor
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
    
    # iOS Simulator
    Write-Host "  → ios-simulator-skill..." -ForegroundColor $InfoColor
    try {
        git clone --depth 1 --quiet https://github.com/conorluddy/ios-simulator-skill.git "$SkillsDir/ios-simulator-skill" 2>$null
        Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
}

# Medium Priority Skills
if ($Priority -eq 'all' -or $Priority -eq 'medium') {
    Write-Host "`n[2/3] Installing Medium Priority Skills..." -ForegroundColor $InfoColor
    
    # Prompt Engineering
    Write-Host "  → prompt-engineering..." -ForegroundColor $InfoColor
    try {
        if (-not (Test-Path "$TempDir/context-kit")) {
            git clone --depth 1 --quiet https://github.com/NeoLabHQ/context-engineering-kit.git $TempDir/context-kit 2>$null
        }
        if (Test-Path "$TempDir/context-kit/plugins/customaize-agent/skills/prompt-engineering") {
            Copy-Item -Path "$TempDir/context-kit/plugins/customaize-agent/skills/prompt-engineering" -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
        }
        else {
            Write-Host "    ✗ Not found in repo" -ForegroundColor $WarningColor
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
    
    # Subagent-Driven Development
    Write-Host "  → subagent-driven-development..." -ForegroundColor $InfoColor
    try {
        if (-not (Test-Path "$TempDir/context-kit")) {
            git clone --depth 1 --quiet https://github.com/NeoLabHQ/context-engineering-kit.git $TempDir/context-kit 2>$null
        }
        if (Test-Path "$TempDir/context-kit/plugins/sadd/skills/subagent-driven-development") {
            Copy-Item -Path "$TempDir/context-kit/plugins/sadd/skills/subagent-driven-development" -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
        }
        else {
            Write-Host "    ✗ Not found in repo" -ForegroundColor $WarningColor
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
    
    # Git Worktrees
    Write-Host "  → using-git-worktrees..." -ForegroundColor $InfoColor
    try {
        if (-not (Test-Path "$TempDir/superpowers")) {
            git clone --depth 1 --quiet https://github.com/obra/superpowers.git $TempDir/superpowers 2>$null
        }
        if (Test-Path "$TempDir/superpowers/skills/using-git-worktrees") {
            Copy-Item -Path "$TempDir/superpowers/skills/using-git-worktrees" -Destination $SkillsDir -Recurse -Force
            Write-Host "    ✓ Installed" -ForegroundColor $SuccessColor
        }
        else {
            Write-Host "    ✗ Not found in repo" -ForegroundColor $WarningColor
        }
    }
    catch {
        Write-Host "    ✗ Failed: $_" -ForegroundColor $ErrorColor
    }
}

# Cleanup
Write-Host "`n[3/3] Cleaning up..." -ForegroundColor $InfoColor
if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}

# Verify installation
Write-Host "`n========================================" -ForegroundColor $SuccessColor
Write-Host "  Installation Summary" -ForegroundColor $SuccessColor
Write-Host "========================================" -ForegroundColor $SuccessColor

$installedSkills = Get-ChildItem $SkillsDir -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "SKILL.md")
}

Write-Host "Total Skills: $($installedSkills.Count)" -ForegroundColor $SuccessColor

# List newly installed skills
$newSkills = @(
    'software-architecture',
    'test-driven-development',
    'ios-simulator-skill',
    'prompt-engineering',
    'subagent-driven-development',
    'using-git-worktrees'
)

Write-Host "`nNewly Installed:" -ForegroundColor $InfoColor
foreach ($skill in $newSkills) {
    if (Test-Path (Join-Path $SkillsDir $skill)) {
        Write-Host "  ✓ $skill" -ForegroundColor $SuccessColor
    }
}

Write-Host "`n========================================`n" -ForegroundColor $SuccessColor
Write-Host "Installation complete! Restart Claude to use new skills." -ForegroundColor $InfoColor
