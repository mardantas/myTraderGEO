<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# PE-EPIC-[N]-[EpicName]-Performance-Checkpoint

**Agent:** PE (Platform Engineer)  
**Project:** [PROJECT_NAME]  
**Date:** [YYYY-MM-DD]  
**Epic:** [EPIC_NUMBER]: [EPIC_NAME]  
**Status:** ✅ Approved / ⚠️ Issues Found / 🔴 Critical Issues  
**Duration:** 15-30 min  
  
---  

## 🎯 Checkpoint Scope

**Triggered by:**  
- [ ] Critical performance path introduced (real-time calculations)  
- [ ] Complex database queries (>3 JOINs)  
- [ ] Epic 4+ (post-MVP stability)  
- [ ] Other: [specify]  

---

## ✅ Performance Checklist

### 1. Database Performance

| Check | Status | Notes |
|-------|--------|-------|
| No N+1 queries detected | ✅ / ⚠️ / 🔴 | [Details if issues found] |
| `.Include()` used for related data | ✅ / ⚠️ / 🔴 | [Details] |
| Indexes on FK/query filters | ✅ / ⚠️ / 🔴 | [Missing indexes if any] |
| Queries <100ms | ✅ / ⚠️ / 🔴 | [Slow queries if any] |

**N+1 Queries Found:**  
```
[List files and line numbers if found]
Example: StrategyRepository.cs:45 - Loading Legs without .Include()
```

**Missing Indexes:**  
```sql
-- Suggested indexes
CREATE INDEX IX_Strategies_UserId ON Strategies(UserId);
CREATE INDEX IX_StrategyLegs_StrategyId ON StrategyLegs(StrategyId);
```

---

### 2. Async/Await Correctness

| Check | Status | Notes |
|-------|--------|-------|
| No `.Result` or `.Wait()` usage | ✅ / ⚠️ / 🔴 | [Files with sync-over-async if found] |
| I/O operations are async | ✅ / ⚠️ / 🔴 | [Details] |
| Async all the way | ✅ / ⚠️ / 🔴 | [Details] |

**Deadlock Risks Found:**  
```
[List files with .Result/.Wait()]
Example: StrategyService.cs:78 - using .Result (deadlock risk)
```

---

### 3. Caching Strategy

| Check | Status | Notes |
|-------|--------|-------|
| Frequently accessed data cached | ✅ / ⚠️ / 🔴 | [What should be cached] |
| Cache invalidation clear | ✅ / ⚠️ / 🔴 | [Details] |
| Cache expiration configured | ✅ / ⚠️ / 🔴 | [Details] |

**Caching Recommendations:**  
```
- Market data (Greeks, prices): Redis, 5-min expiration  
- User preferences: In-Memory, 1-hour expiration  
- Strategy templates: In-Memory, 1-day expiration  
```

---

### 4. Resource Management

| Check | Status | Notes |
|-------|--------|-------|
| Connections/streams disposed | ✅ / ⚠️ / 🔴 | [Files with resource leaks] |
| No memory leaks in loops | ✅ / ⚠️ / 🔴 | [Details] |
| Using `using` statements | ✅ / ⚠️ / 🔴 | [Details] |

---

## 📊 Performance Metrics (if available)

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| API response time (p95) | [X ms] | <500ms | ✅ / ⚠️ / 🔴 |
| Database query time (avg) | [X ms] | <100ms | ✅ / ⚠️ / 🔴 |
| Memory usage | [X MB] | <512MB | ✅ / ⚠️ / 🔴 |

---

## 🔄 Feedback Created

**Critical Issues → FEEDBACK to SE/DBA:**  
- [ ] FEEDBACK-[NNN]-PE-SE-[issue-title].md  
- [ ] FEEDBACK-[NNN]-PE-DBA-[issue-title].md  

**Blocking Deploy:** ☐ Yes ☑ No  

---

## ✅ Final Verdict

- **✅ Approved:** No critical performance issues, epic can proceed to QAE  
- **⚠️ Issues Found:** Non-blocking issues, feedback created for SE/DBA  
- **🔴 Critical Issues:** Blocking issues, must fix before QAE testing  

**Summary:** [Brief summary of checkpoint result]  

---

**Next Steps:**  
- [ ] SE addresses feedback (if any)  
- [ ] DBA addresses feedback (if any)  
- [ ] Epic proceeds to QAE Quality Gate  

---

**Template Version:** 1.0  
**Last Updated:** 2025-10-10  
