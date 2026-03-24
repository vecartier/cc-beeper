---
phase: 14-menu-bar-popover
plan: "01"
subsystem: menu-bar-ui
tags: [swiftui, menu-bar, popover, settings]
dependency_graph:
  requires: []
  provides: [MenuBarPopoverView, QuickActionButton, ThemeDotsRow, SettingsView, SettingsViewModel]
  affects: [ClaumagotchiApp]
tech_stack:
  added: []
  patterns: [MenuBarExtra(.window), environmentObject injection, Timer-based permission polling]
key_files:
  created:
    - Sources/MenuBarPopoverView.swift
    - Sources/QuickActionButton.swift
    - Sources/ThemeDotsRow.swift
    - Sources/SettingsView.swift
    - Sources/SettingsViewModel.swift
  modified:
    - Sources/ClaumagotchiApp.swift
decisions:
  - "MenuBarExtra uses .window style (not .menu) to render SwiftUI popover instead of native dropdown"
  - "Settings window scene added alongside existing main/onboarding windows with id: settings"
  - "Download Voices... URL helper implemented inline in MenuBarPopoverView (not via SettingsViewModel)"
metrics:
  duration: "2 minutes"
  completed_date: "2026-03-24"
  tasks_completed: 2
  files_changed: 6
---

# Phase 14 Plan 01: Menu Bar Popover Summary

Rich popover panel replacing the dropdown MenuBarExtra — SwiftUI popover with YOLO/Mute/Hide/Power quick actions, 8-color theme dots, dark mode toggle, Setup.../Download Voices.../Quit buttons, plus SettingsViewModel for permission polling consumed by Plan 02.

## What Was Built

### Task 1: Popover view components (commit: 4277e4b)

Created three new Swift files:

- **QuickActionButton.swift** — Reusable icon+label button (56x52pt) with active/inactive color states using `.buttonStyle(.plain)` and `RoundedRectangle` background
- **ThemeDotsRow.swift** — 8 color dot picker using hardcoded color map, iterating `ThemeManager.themes`, checkmark overlay on selected theme
- **MenuBarPopoverView.swift** — 320pt popover root with all sections: quick actions HStack, ThemeDotsRow, Dark Mode toggle, Setup.../Download Voices... buttons, Quit button

### Task 2: SettingsView/ViewModel + ClaumagotchiApp rewire (commit: 0a6da22)

- **SettingsViewModel.swift** — `@MainActor` observable with permission polling (AXIsProcessTrusted, AVCaptureDevice, SFSpeechRecognizer) at 2s interval, 4 deep link methods
- **SettingsView.swift** — Form shell with 4 placeholder sections (Audio, Permissions, Voice, About), 460x520pt frame, polling lifecycle hooks
- **ClaumagotchiApp.swift** — MenuBarExtra body rewritten from menu items to `MenuBarPopoverView()` with `.menuBarExtraStyle(.window)`, added `Window("Settings", id: "settings")` scene

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `swift build` passes with zero errors (verified both debug and release)
- All 6 acceptance criteria passed for Task 1
- All 10 acceptance criteria passed for Task 2

## Self-Check: PASSED

Files created:
- Sources/MenuBarPopoverView.swift: FOUND
- Sources/QuickActionButton.swift: FOUND
- Sources/ThemeDotsRow.swift: FOUND
- Sources/SettingsView.swift: FOUND
- Sources/SettingsViewModel.swift: FOUND

Commits:
- 4277e4b: FOUND (feat(14-01): create popover view components)
- 0a6da22: FOUND (feat(14-01): wire Settings window scene and replace dropdown with popover)
