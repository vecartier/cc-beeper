---
phase: 04-notifications
plan: 01
subsystem: notifications
tags: [UserNotifications, UNUserNotificationCenter, macOS, code-signing, UserDefaults]

# Dependency graph
requires:
  - phase: 03-ux-enhancements
    provides: ClaudeMonitor with soundEnabled/autoAccept pattern, processEvent event branches
provides:
  - NotificationManager class wrapping UNUserNotificationCenter with foreground delivery delegate
  - notificationsEnabled UserDefaults-backed property on ClaudeMonitor
  - Notification calls at permission request, session done, tool error, and permission timeout events
  - Ad-hoc code signing in build.sh enabling notification authorization dialog on first launch
affects: [04-notifications plan 02 (menu bar toggle uses notificationsEnabled)]

# Tech tracking
tech-stack:
  added: [UserNotifications framework (built-in macOS 14)]
  patterns:
    - NotificationManager as plain NSObject (not ObservableObject) — fire-and-forget, no published state
    - willPresent delegate returning [.banner, .sound] — required for foreground banner delivery in menu bar apps
    - UNTimeIntervalNotificationTrigger(timeInterval: 0.1) — avoids nil trigger inconsistency on macOS
    - UUID-based notification identifiers — prevents replacing previous notifications
    - notificationsEnabled mirrors soundEnabled pattern exactly (UserDefaults-backed @Published var)

key-files:
  created:
    - Sources/NotificationManager.swift
  modified:
    - Sources/ClaudeMonitor.swift
    - build.sh

key-decisions:
  - "requestPermission() called eagerly in ClaudeMonitor.init() to avoid missing first notification while dialog is pending"
  - "post_tool_error separated from pre_tool/post_tool case to allow targeted notification call"
  - "sendPermissionRequest uses nil-coalescing for pendingPermission (data races with async loadPendingPermission retries)"
  - "Ad-hoc signing (codesign --force --deep --sign -) sufficient for local distribution — no Apple Developer account required"

patterns-established:
  - "New notification send sites follow: if notificationsEnabled { notificationManager.sendXxx(...) }"
  - "UNUserNotificationCenterDelegate.willPresent always returns [.banner, .sound] — never suppress"

requirements-completed: [NOTIF-01, NOTIF-02, NOTIF-03]

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 4 Plan 01: Notifications Summary

**UNUserNotificationCenter integration delivering macOS banners for permission requests, session completions, and tool errors via a foreground-capable NotificationManager with ad-hoc code signing**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-20T14:30:00Z
- **Completed:** 2026-03-20T14:35:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created NotificationManager.swift with UNUserNotificationCenterDelegate conformance, willPresent delegate for foreground delivery, three notification categories, and four send methods
- Wired all notification trigger sites into ClaudeMonitor: permission requests (two branches), permission_timeout, post_tool_error, and session done
- Added notificationsEnabled @Published property defaulting to true, persisted via UserDefaults, matching soundEnabled/autoAccept pattern exactly
- Added ad-hoc codesign step to build.sh — required for UNUserNotificationCenter authorization dialog to appear

## Task Commits

1. **Task 1: Create NotificationManager and add code signing to build.sh** - `e5e6dc0` (feat)
2. **Task 2: Wire NotificationManager into ClaudeMonitor event processing** - `ab29719` (feat)

## Files Created/Modified
- `Sources/NotificationManager.swift` - UNUserNotificationCenter wrapper with delegate for foreground delivery; sendPermissionRequest, sendSessionDone, sendToolError, sendPermissionTimeout
- `Sources/ClaudeMonitor.swift` - Added notificationsEnabled property, notificationManager instance, requestPermission() at init, and four notification send sites in processEvent
- `build.sh` - Added `codesign --force --deep --sign - Claumagotchi.app` after bundle creation

## Decisions Made
- requestPermission() called eagerly at init time, not lazily — avoids missing first notification while permission dialog is pending
- post_tool_error separated into its own switch case to accommodate the sendToolError call without duplicating pre_tool/post_tool logic
- Nil-coalescing fallback (tool: "Unknown") used for sendPermissionRequest because loadPendingPermission is async with retries — pendingPermission may not be populated by the time the permission event fires
- Ad-hoc signing chosen (not full distribution signing) — sufficient for local use, zero configuration required

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- NOTIF-04 (menu bar toggle) is ready: notificationsEnabled property is published and accessible to ClaumagotchiApp.swift
- No blockers for plan 04-02

## Self-Check: PASSED

All files confirmed on disk. Both task commits verified in git log.

---
*Phase: 04-notifications*
*Completed: 2026-03-20*
