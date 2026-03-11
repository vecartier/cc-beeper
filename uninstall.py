#!/usr/bin/env python3
"""Removes Claumagotchi hooks from Claude Code settings."""

import json
import os
import shutil
import subprocess

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
IPC_DIR = os.path.expanduser("~/.claude/claumagotchi")
HOOK_SCRIPT = os.path.join(HOOKS_DIR, "claumagotchi-hook.py")
APP_PATH_FILE = os.path.join(HOOKS_DIR, "claumagotchi-app-path")

HOOK_EVENTS = [
    "PreToolUse", "PostToolUse", "PermissionRequest",
    "Notification", "Stop", "SessionStart", "SessionEnd",
]


def main():
    # Kill running app
    try:
        subprocess.run(["pkill", "-x", "Claumagotchi"],
                       capture_output=True, check=False)
        print("  Stopped Claumagotchi app")
    except Exception:
        pass

    # Remove hook script
    for f in [HOOK_SCRIPT, APP_PATH_FILE]:
        if os.path.exists(f):
            os.remove(f)
            print(f"  Removed {f}")

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
                if not any("claumagotchi-hook.py" in h.get("command", "") for h in rule.get("hooks", []))
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

    # Clean legacy /tmp/ files from older versions
    for f in [
        "/tmp/claumagotchi-events.jsonl",
        "/tmp/claumagotchi-pending.json",
        "/tmp/claumagotchi-response.json",
        "/tmp/claumagotchi-sessions.json",
    ]:
        if os.path.exists(f):
            os.remove(f)

    print()
    print("  Claumagotchi uninstalled!")
    print("  You can safely delete this folder now.")


if __name__ == "__main__":
    main()
