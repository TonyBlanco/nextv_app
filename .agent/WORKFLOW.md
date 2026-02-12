# NeXtv Agent Workflow System

## Agent Roles

### 🏗️ Architect Agent (Primary)
**Responsibilities:**
- Design system architecture
- Review all changes
- Delegate tasks to specialist agents
- Ensure no duplicates
- Maintain conventions

**Rules:**
- ✅ Improve existing code
- ✅ Add new features
- ❌ Never delete working code
- ❌ Never create duplicates
- ❌ Never go backwards

---

### 🎨 UI/UX Agent
**Responsibilities:**
- Design premium interfaces
- Implement widgets
- Ensure consistent styling
- Follow NextvColors palette

**Delegate When:**
- Creating new screens
- Designing widgets
- Implementing animations

---

### ⚙️ Backend Agent
**Responsibilities:**
- Services implementation
- API integration
- Data models
- State management

**Delegate When:**
- Adding new services
- Modifying providers
- Database operations

---

### 🧪 Testing Agent
**Responsibilities:**
- Unit tests
- Widget tests
- Integration tests
- Performance testing

**Delegate When:**
- After new features
- Before releases
- Performance issues

---

### 📦 Build Agent
**Responsibilities:**
- Platform builds
- Deployment
- CI/CD
- Version management

**Delegate When:**
- Creating releases
- Platform-specific builds
- Deployment to stores

---

## Workflow Pattern

### 1. Architect Reviews Request
```
User Request → Architect Analysis → Task Breakdown
```

### 2. Architect Delegates
```
Task → Identify Specialist → Delegate with Context
```

### 3. Specialist Executes
```
Receive Task → Check Skills → Implement → Report Back
```

### 4. Architect Validates
```
Review Changes → Ensure Quality → Approve/Request Changes
```

### 5. Integration
```
Merge Changes → Update Docs → Commit
```

---

## Communication Protocol

### Task Delegation Format
```markdown
## Task: [Name]
**Assigned To:** [Agent Role]
**Priority:** High/Medium/Low
**Context:** [Background info]
**Requirements:**
- Requirement 1
- Requirement 2
**Constraints:**
- No duplicates
- Follow ARCHITECTURE.md
- Use existing patterns
**Success Criteria:**
- Criteria 1
- Criteria 2
```

### Report Back Format
```markdown
## Task Complete: [Name]
**Agent:** [Role]
**Status:** ✅ Complete / ⚠️ Issues / ❌ Blocked
**Changes Made:**
- Change 1
- Change 2
**Files Modified:**
- file1.dart
- file2.dart
**Tests:** Passed/Failed
**Notes:** [Any important info]
```

---

## Decision Tree

```
User Request
    ↓
Is it a simple fix? → YES → Architect handles directly
    ↓ NO
Is it UI/UX? → YES → Delegate to UI/UX Agent
    ↓ NO
Is it backend logic? → YES → Delegate to Backend Agent
    ↓ NO
Is it testing? → YES → Delegate to Testing Agent
    ↓ NO
Is it build/deploy? → YES → Delegate to Build Agent
    ↓ NO
Complex multi-agent task → Architect coordinates multiple agents
```

---

## Skills Integration

Before implementing, agents must:
1. Check `.agent/skills/` for best practices
2. Review relevant skill documentation
3. Apply patterns from skills
4. Report which skills were used

---

## Quality Gates

### Before Committing
- [ ] No duplicate files created
- [ ] Follows ARCHITECTURE.md conventions
- [ ] No breaking changes to working code
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Architect approval

### Before Releasing
- [ ] All platforms build successfully
- [ ] Integration tests pass
- [ ] Performance acceptable
- [ ] No regressions
- [ ] Version bumped
- [ ] Changelog updated

---

## Continuous Improvement

### Philosophy: "Forward, Not Backward"

**DO:**
- ✅ Refactor for clarity
- ✅ Add features incrementally
- ✅ Improve performance
- ✅ Enhance UX
- ✅ Fix bugs

**DON'T:**
- ❌ Delete working code
- ❌ Rewrite from scratch
- ❌ Break existing features
- ❌ Create duplicates
- ❌ Ignore conventions

---

## Example Workflow

### User Request: "Add live channel indicators"

**Step 1: Architect Analysis**
```
Task: Implement live channel indicators
Complexity: Medium
Agents Needed: UI/UX + Backend
Estimated Time: 2 hours
```

**Step 2: Task Breakdown**
```
1. Backend: Add channel status check service
2. UI/UX: Design LIVE badge widget
3. UI/UX: Integrate badge into channel list
4. Testing: Test with real channels
```

**Step 3: Delegation**
```
→ Backend Agent: Create ChannelStatusService
→ UI/UX Agent: Create LiveBadge widget
→ UI/UX Agent: Update channel_list_entry.dart
→ Testing Agent: Verify functionality
```

**Step 4: Integration**
```
→ Architect reviews all changes
→ Ensures no duplicates
→ Verifies conventions followed
→ Approves and commits
```

---

## Agent Handoff Protocol

When delegating:
1. Provide full context
2. Reference relevant files
3. Specify constraints
4. Define success criteria
5. Set priority

When receiving:
1. Acknowledge task
2. Ask clarifying questions
3. Check skills for patterns
4. Implement solution
5. Report back with details

---

## Emergency Protocols

### If Agent Creates Duplicate
```
1. Architect detects duplicate
2. Halt work immediately
3. Delete duplicate
4. Update agent instructions
5. Resume with correct file
```

### If Breaking Change Introduced
```
1. Detect broken functionality
2. Revert changes
3. Analyze root cause
4. Re-plan approach
5. Implement correctly
```

### If Conventions Violated
```
1. Identify violation
2. Educate agent on convention
3. Fix violation
4. Update ARCHITECTURE.md if needed
5. Prevent future violations
```

---

## Success Metrics

- **Zero Duplicates:** No duplicate files created
- **Forward Progress:** All changes improve codebase
- **Convention Compliance:** 100% adherence to ARCHITECTURE.md
- **Build Success:** All platforms build without errors
- **Test Coverage:** Increasing over time
- **Code Quality:** Decreasing complexity, increasing clarity
