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

```bash
# Open project
code "D:\NEXTV APP"

# Install dependencies
flutter pub get

# Build
flutter build apk --release
```

---

For detailed information, see individual files in this directory.
