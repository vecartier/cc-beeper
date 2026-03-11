#!/usr/bin/env python3
"""Claumagotchi hook — forwards Claude Code events, handles permissions, auto-launches app."""

import json
import os
import secrets
import subprocess
import sys
import time

IPC_DIR = os.path.expanduser("~/.claude/claumagotchi")
EVENT_FILE = os.path.join(IPC_DIR, "events.jsonl")
PENDING_FILE = os.path.join(IPC_DIR, "pending.json")
RESPONSE_FILE = os.path.join(IPC_DIR, "response.json")
SESSIONS_FILE = os.path.join(IPC_DIR, "sessions.json")
APP_PATH_FILE = os.path.expanduser("~/.claude/hooks/claumagotchi-app-path")

PERMISSION_TIMEOUT = 55  # seconds (hook timeout is 60s)

EVENT_MAP = {
    "PreToolUse": "pre_tool",
    "PostToolUse": "post_tool",
    "PostToolUseFailure": "post_tool_error",
    "PermissionRequest": "permission",
    "Notification": "notification",
    "Stop": "stop",
    "SessionStart": "session_start",
    "SessionEnd": "session_end",
}


def ensure_ipc_dir():
    """Create IPC directory with owner-only permissions."""
    if not os.path.exists(IPC_DIR):
        os.makedirs(IPC_DIR, mode=0o700, exist_ok=True)
    else:
        os.chmod(IPC_DIR, 0o700)


def safe_write(path, data):
    """Write data to file with 0600 permissions, rejecting symlinks."""
    if os.path.islink(path):
        os.remove(path)
    tmp = path + ".tmp"
    if os.path.islink(tmp):
        os.remove(tmp)
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(data)
    os.replace(tmp, path)


def safe_append(path, line):
    """Append a line to file, creating with 0600 if needed. Rejects symlinks."""
    if os.path.islink(path):
        os.remove(path)
    if not os.path.exists(path):
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        os.close(fd)
    with open(path, "a") as f:
        f.write(line)


def summarize_input(tool, tool_input):
    """Compute a display summary from tool input — avoids leaking full input to disk."""
    if tool == "Bash":
        cmd = tool_input.get("command", "")
        t = cmd[:50]
        return t + "..." if len(cmd) > 50 else t
    elif tool in ("Write", "Read", "Edit", "Glob"):
        path = tool_input.get("file_path", "") or tool_input.get("pattern", "")
        return os.path.basename(path) if path else tool
    elif tool == "Grep":
        return tool_input.get("pattern", "search")
    elif tool == "Agent":
        return tool_input.get("description", "sub-agent")
    else:
        return tool.lower()


def get_app_path():
    """Read app path from config file, fall back to common locations."""
    if os.path.exists(APP_PATH_FILE):
        with open(APP_PATH_FILE) as f:
            path = f.read().strip()
            if os.path.exists(path):
                return path
    for candidate in [
        os.path.expanduser("~/Desktop/Claumagotchi/Claumagotchi.app"),
        os.path.expanduser("~/Claumagotchi/Claumagotchi.app"),
        os.path.expanduser("~/Projects/Claumagotchi/Claumagotchi.app"),
        os.path.expanduser("~/Developer/Claumagotchi/Claumagotchi.app"),
    ]:
        if os.path.exists(candidate):
            return candidate
    return None


def write_event(event_type, tool="", extra=None):
    """Append an event to the events file, truncating if it exceeds 50KB."""
    try:
        if os.path.exists(EVENT_FILE) and os.path.getsize(EVENT_FILE) > 50 * 1024:
            with open(EVENT_FILE, "r") as f:
                lines = f.readlines()
            safe_write(EVENT_FILE, "".join(lines[-20:]))
    except OSError:
        pass

    out = {"event": event_type, "tool": tool, "ts": int(time.time())}
    if extra:
        out.update(extra)
    safe_append(EVENT_FILE, json.dumps(out) + "\n")


def track_session(session_id, action):
    """Track active sessions."""
    sessions = {}
    if os.path.exists(SESSIONS_FILE):
        try:
            with open(SESSIONS_FILE) as f:
                sessions = json.load(f)
        except (json.JSONDecodeError, IOError):
            sessions = {}

    if action == "start":
        sessions[session_id] = int(time.time())
    elif action == "end":
        sessions.pop(session_id, None)

    now = int(time.time())
    sessions = {k: v for k, v in sessions.items() if now - v < 7200}

    safe_write(SESSIONS_FILE, json.dumps(sessions))


def ensure_app_running():
    """Launch Claumagotchi if not already running."""
    result = subprocess.run(["pgrep", "-x", "Claumagotchi"], capture_output=True)
    if result.returncode != 0:
        app_path = get_app_path()
        if app_path:
            subprocess.Popen(["open", app_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def handle_permission(data):
    """Handle PermissionRequest — block and wait for user response from app."""
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    req_id = secrets.token_hex(16)

    pending = {
        "id": req_id,
        "tool": tool,
        "summary": summarize_input(tool, tool_input),
        "ts": int(time.time()),
    }
    safe_write(PENDING_FILE, json.dumps(pending))

    write_event("permission", tool=tool)

    start = time.time()
    while time.time() - start < PERMISSION_TIMEOUT:
        if os.path.exists(RESPONSE_FILE):
            try:
                with open(RESPONSE_FILE) as f:
                    resp = json.load(f)
                if resp.get("id") == req_id:
                    try:
                        os.remove(RESPONSE_FILE)
                    except OSError:
                        pass
                    try:
                        os.remove(PENDING_FILE)
                    except OSError:
                        pass

                    decision = resp.get("decision", "allow")
                    output = {
                        "hookSpecificOutput": {
                            "hookEventName": "PermissionRequest",
                            "decision": {
                                "behavior": decision,
                                "message": f"{'Approved' if decision == 'allow' else 'Denied'} via Claumagotchi",
                            },
                        }
                    }
                    print(json.dumps(output))
                    return
            except (json.JSONDecodeError, KeyError, IOError):
                pass
        time.sleep(0.3)

    try:
        os.remove(PENDING_FILE)
    except OSError:
        pass
    write_event("permission_timeout")


def main():
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, EOFError):
        return

    ensure_ipc_dir()

    event_name = data.get("hook_event_name", "")
    session_id = data.get("session_id", "")

    if event_name == "SessionStart":
        ensure_app_running()
        track_session(session_id, "start")

    if event_name == "SessionEnd":
        track_session(session_id, "end")

    if event_name == "PermissionRequest":
        handle_permission(data)
        return

    mapped = EVENT_MAP.get(event_name)
    if not mapped:
        return

    out = {"event": mapped, "tool": data.get("tool_name", ""), "ts": int(time.time())}

    if event_name == "Notification":
        out["type"] = data.get("notification_type", "")

    safe_append(EVENT_FILE, json.dumps(out) + "\n")


if __name__ == "__main__":
    main()
