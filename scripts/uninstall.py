#!/usr/bin/env python3
"""Removes CC-Beeper hooks from Claude Code settings."""

import json
import os
import shutil
import subprocess

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
IPC_DIR = os.path.expanduser("~/.claude/cc-beeper")
HOOK_SCRIPT = os.path.join(HOOKS_DIR, "cc-beeper-hook.py")

HOOK_EVENTS = [
    "PreToolUse", "PostToolUse", "PermissionRequest",
    "Notification", "Stop", "SessionStart", "SessionEnd",
]


def main():
    # Kill running app
    try:
        subprocess.run(["pkill", "-x", "CC-Beeper"],
                       capture_output=True, check=False)
        print("  Stopped CC-Beeper app")
    except Exception:
        pass

    # Remove hook script
    if os.path.exists(HOOK_SCRIPT):
        os.remove(HOOK_SCRIPT)
        print(f"  Removed {HOOK_SCRIPT}")

    # Clean hooks from settings
    if os.path.exists(SETTINGS_PATH):
        try:
            with open(SETTINGS_PATH) as f:
                settings = json.load(f)
        except (json.JSONDecodeError, IOError):
            print(f"  WARNING: Could not parse {SETTINGS_PATH}")
            return

        hooks = settings.get("hooks", {})
        changed = False

        for event in HOOK_EVENTS:
            existing = hooks.get(event, [])
            filtered = [
                rule for rule in existing
                if not any(
                    "cc-beeper-hook.py" in h.get("command", "")
                    for h in rule.get("hooks", [])
                )
            ]
            if len(filtered) != len(existing):
                changed = True
                if filtered:
                    hooks[event] = filtered
                else:
                    del hooks[event]

        if changed:
            settings["hooks"] = hooks
            with open(SETTINGS_PATH, "w") as f:
                json.dump(settings, f, indent=2)
            print(f"  Cleaned hooks from {SETTINGS_PATH}")

    # Clean IPC directory
    if os.path.exists(IPC_DIR):
        shutil.rmtree(IPC_DIR)
        print(f"  Removed {IPC_DIR}")

    print()
    print("  CC-Beeper uninstalled!")
    print("  You can safely delete this folder now.")


if __name__ == "__main__":
    main()
