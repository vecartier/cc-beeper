#!/usr/bin/env python3
"""Sets up CC-Beeper hooks in Claude Code settings."""

import json
import os
import shutil

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
IPC_DIR = os.path.expanduser("~/.claude/cc-beeper")
HOOK_SCRIPT = os.path.join(HOOKS_DIR, "cc-beeper-hook.py")
APP_PATH_FILE = os.path.join(HOOKS_DIR, "cc-beeper-app-path")
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Events and their hook configs
HOOK_CONFIGS = {
    "PreToolUse":        {"timeout": 5},
    "PostToolUse":       {"timeout": 5},
    "PostToolUseFailure": {"timeout": 5},
    "PermissionRequest": {"timeout": 60},  # longer — waits for user response
    "Notification":      {"timeout": 5},
    "Stop":              {"timeout": 5},
    "SessionStart":      {"timeout": 10},  # may launch app
    "SessionEnd":        {"timeout": 5},
}


def main():
    # Ensure ~/.claude exists
    os.makedirs(os.path.expanduser("~/.claude"), exist_ok=True)

    # Create IPC directory with owner-only permissions
    os.makedirs(IPC_DIR, mode=0o700, exist_ok=True)
    os.chmod(IPC_DIR, 0o700)
    print(f"  IPC directory created -> {IPC_DIR}")

    # Install hook script
    os.makedirs(HOOKS_DIR, exist_ok=True)
    src = os.path.join(SCRIPT_DIR, "hooks", "cc-beeper-hook.py")
    if not os.path.exists(src):
        print(f"  ERROR: Hook script not found at {src}")
        return
    shutil.copy2(src, HOOK_SCRIPT)
    os.chmod(HOOK_SCRIPT, 0o755)
    print(f"  Hook script installed -> {HOOK_SCRIPT}")

    # Write app path so hook knows where to find the .app bundle
    # Prefer /Applications if installed there, otherwise use local build
    if os.path.exists("/Applications/CC-Beeper.app"):
        app_path = "/Applications/CC-Beeper.app"
    else:
        app_path = os.path.join(SCRIPT_DIR, "CC-Beeper.app")
    with open(APP_PATH_FILE, "w") as f:
        f.write(app_path)
    print(f"  App path saved -> {APP_PATH_FILE}")

    # Load existing settings
    settings = {}
    if os.path.exists(SETTINGS_PATH):
        try:
            with open(SETTINGS_PATH) as f:
                settings = json.load(f)
        except (json.JSONDecodeError, IOError):
            print(f"  WARNING: Could not parse {SETTINGS_PATH}, starting fresh")
            settings = {}

    # Remove old cc-beeper hooks, then add fresh ones
    hooks = settings.get("hooks", {})
    cmd = f"python3 {HOOK_SCRIPT}"

    for event, cfg in HOOK_CONFIGS.items():
        existing = hooks.get(event, [])
        # Remove previous cc-beeper entries
        existing = [
            rule for rule in existing
            if not any("cc-beeper-hook.py" in h.get("command", "") for h in rule.get("hooks", []))
        ]
        # Add fresh entry
        hook_entry = {"type": "command", "command": cmd}
        if "timeout" in cfg:
            hook_entry["timeout"] = cfg["timeout"]
        existing.append({"matcher": "", "hooks": [hook_entry]})
        hooks[event] = existing

    settings["hooks"] = hooks

    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f, indent=2)

    print(f"  Hooks configured in {SETTINGS_PATH}")
    print()
    print("  CC-Beeper is ready!")
    print("  The app auto-launches when you start a Claude Code session.")
    print(f"  You can also launch manually: open {app_path}")


if __name__ == "__main__":
    main()
