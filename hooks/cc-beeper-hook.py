#!/usr/bin/env python3
"""CC-Beeper hook — forwards Claude Code events, handles permissions, auto-launches app."""

import json
import os
import secrets
import subprocess
import sys
import time

IPC_DIR = os.path.expanduser("~/.claude/cc-beeper")
EVENT_FILE = os.path.join(IPC_DIR, "events.jsonl")
PENDING_FILE = os.path.join(IPC_DIR, "pending.json")
RESPONSE_FILE = os.path.join(IPC_DIR, "response.json")
SESSIONS_FILE = os.path.join(IPC_DIR, "sessions.json")
SUMMARY_FILE = os.path.join(IPC_DIR, "last_summary.txt")
APP_PATH_FILE = os.path.expanduser("~/.claude/hooks/cc-beeper-app-path")
PID_FILE = os.path.join(IPC_DIR, "cc-beeper.pid")

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
        if not path:
            return tool.lower()
        return path if len(path) <= 40 else "..." + path[-37:]
    elif tool == "Grep":
        return tool_input.get("pattern", "search")
    elif tool == "Agent":
        return tool_input.get("description", "sub-agent")
    else:
        return tool.lower()


def get_session_jsonl(session_id):
    """Find the JSONL file for a given session ID."""
    claude_dir = os.path.expanduser("~/.claude/projects")
    for root, dirs, files in os.walk(claude_dir):
        for f in files:
            if f == f"{session_id}.jsonl":
                return os.path.join(root, f)
    return None


def get_most_recent_jsonl():
    """Fallback: find the most recently modified JSONL."""
    claude_dir = os.path.expanduser("~/.claude/projects")
    newest = None
    newest_time = 0
    for root, dirs, files in os.walk(claude_dir):
        for f in files:
            if f.endswith(".jsonl"):
                path = os.path.join(root, f)
                mtime = os.path.getmtime(path)
                if mtime > newest_time:
                    newest_time = mtime
                    newest = path
    return newest


def extract_last_assistant_text(jsonl_path):
    """Read JSONL, find last assistant message with text content."""
    if not jsonl_path or not os.path.exists(jsonl_path):
        return ""
    last_text = ""
    with open(jsonl_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                if obj.get("type") != "assistant":
                    continue
                message = obj.get("message", {})
                content = message.get("content", [])
                texts = [b.get("text", "").strip()
                         for b in content if b.get("type") == "text"]
                texts = [t for t in texts if t]
                if texts:
                    last_text = "\n\n".join(texts)
            except (json.JSONDecodeError, KeyError, TypeError):
                continue
    return last_text


def is_pid_alive(pid):
    """Check if a process with the given PID is still running."""
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False


def is_app_running_by_pid():
    """Check the PID file to see if CC-Beeper is already running."""
    try:
        if os.path.exists(PID_FILE):
            with open(PID_FILE) as f:
                pid = int(f.read().strip())
            return is_pid_alive(pid)
    except (ValueError, IOError):
        pass
    return False


def get_app_path():
    """Read app path from config file, fall back to common locations."""
    if os.path.exists(APP_PATH_FILE):
        with open(APP_PATH_FILE) as f:
            path = f.read().strip()
            if os.path.exists(path):
                return path
    for candidate in [
        "/Applications/CC-Beeper.app",
        os.path.expanduser("~/Applications/CC-Beeper.app"),
        os.path.expanduser("~/Desktop/cc-beeper/CC-Beeper.app"),
        os.path.expanduser("~/cc-beeper/CC-Beeper.app"),
        os.path.expanduser("~/Projects/cc-beeper/CC-Beeper.app"),
        os.path.expanduser("~/Developer/cc-beeper/CC-Beeper.app"),
    ]:
        if os.path.exists(candidate):
            return candidate
    return None


def write_event(event_type, tool="", sid="", extra=None):
    """Append an event to the events file, truncating if it exceeds 50KB."""
    try:
        if os.path.exists(EVENT_FILE) and os.path.getsize(EVENT_FILE) > 50 * 1024:
            with open(EVENT_FILE, "r") as f:
                lines = f.readlines()
            safe_write(EVENT_FILE, "".join(lines[-20:]))
    except OSError:
        pass

    out = {"event": event_type, "tool": tool, "ts": int(time.time()), "sid": sid}
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
    """Launch CC-Beeper if not already running, with lock to prevent race conditions."""
    # Fast path: PID file says it's already running — no need for pgrep or locking.
    if is_app_running_by_pid():
        return

    lock_file = os.path.join(IPC_DIR, ".launch.lock")
    lock_fd = None
    try:
        import fcntl

        lock_fd = os.open(lock_file, os.O_WRONLY | os.O_CREAT, 0o600)
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except (OSError, IOError):
            # Another hook instance is already launching — skip
            return

        # Re-check after acquiring lock (another hook may have just launched it).
        if is_app_running_by_pid():
            return

        result = subprocess.run(["pgrep", "-x", "CC-Beeper"], capture_output=True)
        if result.returncode != 0:
            app_path = get_app_path()
            if app_path:
                subprocess.Popen(
                    ["open", "-g", app_path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                # Brief wait so the app writes its PID file
                time.sleep(1.0)
    finally:
        if lock_fd is not None:
            try:
                import fcntl

                fcntl.flock(lock_fd, fcntl.LOCK_UN)
            except (OSError, IOError):
                pass
            os.close(lock_fd)


def handle_permission(data, session_id=""):
    """Handle PermissionRequest — block and wait for user response from app."""
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})
    req_id = secrets.token_hex(16)
    pending_ts = int(time.time())

    pending = {
        "id": req_id,
        "tool": tool,
        "summary": summarize_input(tool, tool_input),
        "ts": pending_ts,
    }
    safe_write(PENDING_FILE, json.dumps(pending))

    write_event("permission", tool=tool, sid=session_id)

    start = time.time()
    while time.time() - start < PERMISSION_TIMEOUT:
        if os.path.exists(RESPONSE_FILE):
            try:
                with open(RESPONSE_FILE) as f:
                    resp = json.load(f)
                if resp.get("id") == req_id:
                    # Freshness: reject responses written before pending was issued
                    resp_mtime = os.path.getmtime(RESPONSE_FILE)
                    if resp_mtime < pending_ts - 2:
                        try:
                            os.remove(RESPONSE_FILE)
                        except OSError:
                            pass
                        time.sleep(0.3)
                        continue
                    try:
                        os.remove(RESPONSE_FILE)
                    except OSError:
                        pass
                    try:
                        os.remove(PENDING_FILE)
                    except OSError:
                        pass

                    decision = resp.get("decision", "deny")
                    if decision not in ("allow", "deny"):
                        decision = "deny"
                    output = {
                        "hookSpecificOutput": {
                            "hookEventName": "PermissionRequest",
                            "decision": {
                                "behavior": decision,
                                "message": f"{'Approved' if decision == 'allow' else 'Denied'} via CC-Beeper",
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
    write_event("permission_timeout", sid=session_id)


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
        handle_permission(data, session_id=session_id)
        return

    mapped = EVENT_MAP.get(event_name)
    if not mapped:
        return

    out = {"event": mapped, "tool": data.get("tool_name", ""), "ts": int(time.time()), "sid": session_id}

    if event_name == "Notification":
        out["type"] = data.get("notification_type", "")

    safe_append(EVENT_FILE, json.dumps(out) + "\n")

    # Extract summary on Stop — triggers TTS via ClaudeMonitor file watcher
    if event_name == "Stop":
        jsonl_path = None
        if session_id:
            jsonl_path = get_session_jsonl(session_id)
        if not jsonl_path:
            jsonl_path = get_most_recent_jsonl()
        text = extract_last_assistant_text(jsonl_path)
        if text:
            safe_write(SUMMARY_FILE, text)


if __name__ == "__main__":
    main()
