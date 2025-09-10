# Next Steps Action Plan - ZSH Redesign

**Generated:** 2025-09-10 (Part 08.18)  
**Current Position:** Stage 3 at 92% completion  
**Target:** Stage 4 Feature Layer Implementation

---

## Migration & Runner Upgrade (Completed)

- All CI workflows and documentation now use `run-all-tests-v2.zsh`
- Legacy runner deprecated and marked in all references
- Standards-compliant isolation (`zsh -f`) enforced for all tests
- Manifest test passes in isolation and CI
- Performance: 334ms startup, 1.9% variance

---

## Immediate Actions (This Week)

### 1. Run Comprehensive Test Suite
```bash
cd ~/dotfiles/dot-config/zsh
./tests/run-all-tests-v2.zsh 2>&1 | tee logs/full-test-$(date +%Y%m%d).log
```

### 2. Run Unit Tests Specifically
```bash
./tests/run-all-tests-v2.zsh --unit-only
```

### 3. Verify Manifest Test in Isolation
```bash
zsh -f tests/unit/core/test-core-functions-manifest.zsh
```

### 4. Document Any Failures
```bash
grep -E "FAIL|ERROR" logs/full-test-*.log > logs/test-failures.txt
```

---

## Migration Tool End-to-End Test
```bash
export TEST_HOME="$HOME/.zsh-test-migration"
mkdir -p "$TEST_HOME"
cp ~/.zshenv "$TEST_HOME/.zshenv.backup"

# Run migration dry-run
./tools/migrate-to-redesign.sh --dry-run \
  --zshenv "$TEST_HOME/.zshenv" \
  --backup-dir "$TEST_HOME/backups"

# Apply migration
./tools/migrate-to-redesign.sh --apply \
  --zshenv "$TEST_HOME/.zshenv" \
  --backup-dir "$TEST_HOME/backups"
```

---

## Actionable Sequence

1. Run full test suite with new runner and document any failures
2. Monitor CI ledger for 7-day stability window
3. Finalize documentation and onboarding guides
4. Prepare for Stage 4: Feature Layer Implementation
5. Continue updating trackers as new tasks are discovered


# 4. Test rollback
./tools/migrate-to-redesign.sh --restore \
  --zshenv "$TEST_HOME/.zshenv" \
  --backup-dir "$TEST_HOME/backups"
```

### Day 4-5: Performance Baseline Lock
```bash
# 1. Capture 10-run baseline
./tools/perf-capture-multi.zsh -n 10 --output docs/redesignv2/artifacts/metrics/baseline-lock.json

# 2. Verify consistency
jq '.captures[].post_plugin_total_ms' docs/redesignv2/artifacts/metrics/baseline-lock.json

# 3. Update badges
./tools/update-variance-and-badges.zsh

# 4. Commit baseline
git add docs/redesignv2/artifacts/metrics/baseline-lock.json
git commit -m "perf: lock Stage 3 performance baseline at 334ms"
```

## Week 2: Stage 3 Completion

### Complete 7-Day CI Stability Window
- **Day 6-7 of window:** Monitor nightly captures
- **Action if drift detected:** Investigate and document
- **Success criteria:** No regressions > 5% for 7 consecutive days

### Documentation Finalization
1. Update all progress trackers to 100%
2. Create Stage 3 completion report
3. Archive completed task tickets
4. Update roadmap with Stage 4 details

### Stage 3 Sign-off Checklist
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Performance metrics stable (< 350ms, variance < 5%)
- [ ] Migration tools tested and documented
- [ ] 7-day CI window complete
- [ ] Documentation current
- [ ] Team review conducted

## Week 3-4: Stage 4 Preparation

### Planning & Design
1. **Feature Inventory**
   ```bash
   # Audit current features to migrate
   grep -r "function\|alias" ~/.zshrc* > feature-inventory.txt
   
   # Categorize by priority
   # P0: Git, Docker, core dev tools
   # P1: Language-specific tools
   # P2: Custom utilities
   ```

2. **Module Structure Design**
   ```
   .zshrc.features.d.REDESIGN/
   ├── 10-git-integration.zsh
   ├── 20-docker-tools.zsh
   ├── 30-language-support.zsh
   ├── 40-development-utils.zsh
   └── 50-custom-functions.zsh
   ```

3. **Lazy Loading Strategy**
   - Define trigger points for feature loading
   - Create dependency graph
   - Design caching mechanism

### Implementation Start
1. **Create feature module templates**
2. **Implement first feature module (git)**
3. **Add feature-specific tests**
4. **Measure performance impact**

## Month 2: Stage 4-5 Execution

### Week 5-6: Feature Layer Implementation
- Migrate all P0 features
- Implement lazy loading framework
- Add comprehensive tests
- Performance optimization

### Week 7-8: UI & Completion System
- Async prompt implementation
- Completion optimization
- Terminal compatibility testing
- User acceptance testing

## Success Metrics & Gates

### Stage 3 → Stage 4 Gate
Must achieve ALL:
- ✅ Performance < 350ms (current: 334ms)
- ✅ Variance < 5% (current: 1.9%)
- ✅ Core tests passing (manifest test fixed)
- ⏳ 7-day stability (day 3/7)
- ⏳ Migration tested end-to-end
- ⏳ Documentation complete

### Stage 4 → Stage 5 Gate
Must achieve:
- [ ] All features migrated
- [ ] Lazy loading operational
- [ ] Performance maintained (< 400ms with features)
- [ ] No feature regressions
- [ ] User testing complete

## Risk Mitigation Actions

### Performance Regression Prevention
```bash
# Before any major change
./tools/perf-capture-multi.zsh -n 5 --output before.json

# After change
./tools/perf-capture-multi.zsh -n 5 --output after.json

# Compare
./tools/perf-diff.zsh before.json after.json
```

### Rollback Preparation
```bash
# Tag current stable state
git tag -a stage3-stable -m "Stage 3 stable baseline"

# Create rollback branch
git checkout -b rollback/stage3-stable

# Document rollback procedure
echo "Rollback: git checkout rollback/stage3-stable" > ROLLBACK.md
```

## Communication Plan

### Weekly Updates
- **Monday:** Sprint planning & task assignment
- **Wednesday:** Progress check & blocker review
- **Friday:** Test results & performance report

### Stakeholder Notifications
- **Stage 3 Completion:** Detailed report with metrics
- **Stage 4 Start:** Feature migration plan & timeline
- **Go-Live Decision:** Risk assessment & rollback plan

## Quick Command Reference

```bash
# Daily health check
make test-quick
make perf-check
make badge-update

# Weekly validation
make test-full
make perf-baseline
make docs-update

# Stage transition
make stage-complete
make stage-archive
make stage-next
```

## Contact & Support

- **Primary:** Review current task tracker
- **Issues:** Create tickets in tracking system
- **Urgent:** Check TASK_TRACKER.md for current priorities

---

**Next Update:** After Stage 3 completion (est. 2025-09-17)
**Stage 4 Kickoff:** 2025-10-01
**Full Migration Target:** 2025-11-01