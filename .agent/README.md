# NeXtv Agent System

Welcome to the NeXtv multi-agent development system.

## Quick Start

### For Architect Agent
1. Read `WORKFLOW.md` for delegation patterns
2. Review `ENVIRONMENT.md` for SDK paths
3. Check `skills/` for best practices
4. Follow "Forward, Not Backward" philosophy

### For Specialist Agents
1. Receive task from Architect
2. Check relevant skill in `skills/`
3. Implement following conventions
4. Report back to Architect

---

## Core Files

- **WORKFLOW.md** - Multi-agent coordination
- **ENVIRONMENT.md** - SDK & tool configuration
- **skills/nextv_flutter_iptv/SKILL.md** - Development patterns

---

## Philosophy

### Forward, Not Backward
- ✅ Improve existing code
- ✅ Add new features
- ❌ Delete working code
- ❌ Create duplicates

### Quality First
- No duplicates
- Follow conventions
- Test before commit
- Document changes

---

## Agent Roles

1. **Architect** - Design & coordinate
2. **UI/UX** - Interface design
3. **Backend** - Services & logic
4. **Testing** - Quality assurance
5. **Build** - Deployment

---

## Getting Started

### macOS (primary)
```bash
cd /Users/luisblancofontela/Development/nextv_app
export PATH="$HOME/.gemini/antigravity/scratch/flutter_sdk/bin:$PATH"
flutter pub get
flutter run
```

### Windows
```powershell
cd $env:USERPROFILE\Development\nextv_app
flutter pub get
flutter build windows --release
```

---

## Installed AI Tools

| Tool | Command | Purpose |
|------|---------|--------|
| GitHub Copilot | VS Code extension | Code completion & chat |
| Claude Code | `claude` | Anthropic AI terminal agent |
| Copilot CLI | `gh copilot suggest` | Shell suggestions |
| gh CLI | `gh` | GitHub API from terminal |
| Gemini | `~/.gemini/` | Google AI agent |

## UI/UX Tools

| Tool | Command | Purpose |
|------|---------|--------|
| Figma | `/Applications/Figma.app` | Interface design |
| Device Preview | `enableDevicePreview = true` in main.dart | Multi-device preview |
| Widgetbook | `flutter run -t lib/widgetbook/widgetbook_app.dart` | Widget catalog |
| ImageMagick | `magick` | Image processing |
| FFmpeg | `ffmpeg` | Video processing |

---

For detailed information, see individual files in this directory.
