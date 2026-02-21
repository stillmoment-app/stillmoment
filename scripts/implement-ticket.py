#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# ///
"""Autonomous ticket implementation orchestrator.

Reads a ticket, implements it via TDD, reviews, fixes, and closes it —
all without manual interaction. Agents communicate through a shared log file.
"""

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
import threading
import time
from datetime import datetime
from pathlib import Path

# --- Constants ---

MAX_REVIEWS = 5
MAX_TURNS_IMPLEMENT = 300
MAX_TURNS_REVIEW = 60
MAX_TURNS_FIX = 60
MAX_TURNS_CLOSE = 30

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# --- Tool lists ---

SHARED_TOOLS = [
    "Read", "Glob", "Grep",
    # Build & test
    "Bash(make:*)",
    "Bash(xcodebuild:*)",
    "Bash(xcrun:*)",
    "Bash(sw_vers:*)",
    "Bash(swiftc:*)",
    "Bash(bash -n:*)",
    "Bash(./gradlew:*)",
    # Git (read-only)
    "Bash(git status:*)",
    "Bash(git show:*)",
    "Bash(git show-ref:*)",
    "Bash(git diff:*)",
    "Bash(git log:*)",
    # File utilities
    "Bash(ls:*)",
    "Bash(find:*)",
    "Bash(grep:*)",
    "Bash(cat:*)",
    "Bash(wc:*)",
    "Bash(tree:*)",
    "Bash(tr:*)",
    "Bash(echo:*)",
    "Bash(sips:*)",
    # MCP tools
    "mcp__XcodeBuildMCP__build_sim",
    "mcp__XcodeBuildMCP__list_schemes",
    "mcp__XcodeBuildMCP__session-set-defaults",
    "mcp__XcodeBuildMCP__session-show-defaults",
    "mcp__XcodeBuildMCP__discover_projs",
]

IMPLEMENTER_TOOLS = SHARED_TOOLS + [
    "Edit", "Write",
    "Bash(git add:*)",
    "Bash(git commit:*)",
    "Skill(close-ticket)",
]

REVIEWER_TOOLS = SHARED_TOOLS + [
    "Bash(tee -a dev-docs/tickets/logs/*)",
    "Skill(review-code)",
    "Skill(review-localization)",
]


def build_tools_arg(tools: list[str]) -> str:
    return ",".join(tools)


# --- Argument parsing ---


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Implement a ticket autonomously via Claude agents.",
    )
    parser.add_argument("ticket_id", help="Ticket ID (e.g. ios-032, android-015, shared-040)")
    parser.add_argument(
        "--platform",
        choices=["ios", "android"],
        help="Target platform (required for shared-* tickets, auto-detected otherwise)",
    )
    return parser.parse_args()


# --- Platform detection ---


def detect_platform(ticket_id: str, platform_arg: str | None) -> str:
    if platform_arg:
        return platform_arg
    if ticket_id.startswith("ios-"):
        return "ios"
    if ticket_id.startswith("android-"):
        return "android"
    if ticket_id.startswith("shared-"):
        print("Error: shared tickets need --platform ios|android")
        sys.exit(1)
    print("Error: invalid ticket ID format (expected ios-NNN, android-NNN, or shared-NNN)")
    sys.exit(1)


# --- Preflight checks ---


def preflight_checks(ticket_id: str) -> Path:
    """Check git status and find ticket file. Returns the ticket file path."""
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True, text=True, cwd=PROJECT_ROOT,
    )
    if result.stdout.strip():
        print("Error: uncommitted changes. Commit or stash first.")
        sys.exit(1)

    # Find ticket file
    tickets_dir = PROJECT_ROOT / "dev-docs" / "tickets"
    matches = list(tickets_dir.glob(f"{ticket_id}-*.md")) + list(tickets_dir.glob(f"{ticket_id}.md"))
    if not matches:
        print(f"Error: ticket file not found for {ticket_id}")
        sys.exit(1)
    return matches[0].relative_to(PROJECT_ROOT)


def check_prior_run(branch: str, log_file: Path, ticket_id: str) -> None:
    """Abort if a prior run exists (branch or log file)."""
    branch_exists = subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
        cwd=PROJECT_ROOT,
    ).returncode == 0
    log_exists = (PROJECT_ROOT / log_file).is_file()

    if branch_exists or log_exists:
        print(f"Error: Vorheriger Lauf fuer {ticket_id} gefunden.")
        if branch_exists:
            print(f"  Branch: {branch}")
        if log_exists:
            print(f"  Log:    {log_file}")
        print()
        print("Optionen:")
        cleanup_parts = []
        if branch_exists:
            cleanup_parts.append(f"git branch -D {branch}")
        if log_exists:
            cleanup_parts.append(f"rm {log_file}")
        cleanup = " && ".join(cleanup_parts)
        print(f"  Neu starten:  {cleanup} && make implement TICKET={ticket_id}")
        if log_exists:
            print(f"  Log ansehen:  cat {log_file}")
        sys.exit(1)


# --- Branch and log ---


def create_branch(branch: str) -> None:
    subprocess.run(["git", "checkout", "-b", branch, "main"], check=True, cwd=PROJECT_ROOT)


def init_log(log_file: Path, ticket_id: str, ticket_file: Path, platform: str, branch: str) -> None:
    full_path = PROJECT_ROOT / log_file
    full_path.parent.mkdir(parents=True, exist_ok=True)
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    full_path.write_text(
        f"# Implementation Log: {ticket_id}\n"
        f"\n"
        f"Ticket: {ticket_file}\n"
        f"Platform: {platform}\n"
        f"Branch: {branch}\n"
        f"Started: {now}\n"
    )


# --- JSONL stream monitor ---


def summarize_tool(name: str, inp: dict) -> str:
    cwd = str(PROJECT_ROOT) + "/"
    if name == "Read":
        return inp.get("file_path", "").replace(cwd, "")
    if name == "Glob":
        return inp.get("pattern", "")
    if name == "Grep":
        path = inp.get("path", "").replace(cwd, "")
        pat = inp.get("pattern", "")
        return f'"{pat}" in {path}' if path else f'"{pat}"'
    if name == "Edit":
        return inp.get("file_path", "").replace(cwd, "")
    if name == "Write":
        return inp.get("file_path", "").replace(cwd, "")
    if name == "Bash":
        cmd = inp.get("command", "")
        if "git commit" in cmd:
            msg = cmd.split("-m")[-1].strip().strip("'\"")[:80] if "-m" in cmd else ""
            return f"commit: {msg}" if msg else "git commit"
        return cmd[:100]
    if name == "Skill":
        return inp.get("skill", "")
    return str(inp)[:80]


def monitor_stream(phase: str, stream_file: str, process: subprocess.Popen, start_time: float) -> None:
    """Monitor JSONL stream file in a thread, printing agent activity."""

    def fmt_time() -> str:
        elapsed = int(time.time() - start_time)
        return f"{elapsed // 60}:{elapsed % 60:02d}"

    last_pos = 0
    idle_count = 0

    while process.poll() is None:
        time.sleep(2)
        try:
            size = os.path.getsize(stream_file)
        except OSError:
            continue
        if size <= last_pos:
            idle_count += 1
            if idle_count >= 15:  # 30s without output
                print(f"  [{phase} {fmt_time()}] working...", flush=True)
                idle_count = 0
            continue
        idle_count = 0
        with open(stream_file) as f:
            f.seek(last_pos)
            new_data = f.read()
            last_pos = f.tell()
        _process_jsonl_lines(new_data, phase, fmt_time)

    # Process remaining lines after agent exits
    try:
        with open(stream_file) as f:
            f.seek(last_pos)
            remaining = f.read()
        _process_jsonl_lines(remaining, phase, fmt_time)
    except OSError:
        pass


def _process_jsonl_lines(data: str, phase: str, fmt_time) -> None:
    for line in data.strip().split("\n"):
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("type") == "result":
            turns = obj.get("num_turns", "?")
            cost = obj.get("total_cost_usd", 0)
            print(f"  [{phase} {fmt_time()}] done: turns={turns} cost=${cost:.2f}", flush=True)
        elif obj.get("type") == "assistant":
            for block in obj.get("message", {}).get("content", []):
                if block.get("type") == "tool_use":
                    name = block.get("name", "?")
                    inp = block.get("input", {})
                    detail = summarize_tool(name, inp)
                    print(f"  [{phase} {fmt_time()}] {name} {detail}", flush=True)


# --- Agent execution ---


def run_agent(phase: str, cmd: list[str], log_file: Path, branch: str) -> None:
    """Run a claude agent with JSONL progress monitoring."""
    fd, stream_file = tempfile.mkstemp(prefix="implement-stream-", suffix=".jsonl")
    os.close(fd)

    try:
        with open(stream_file, "w") as out:
            process = subprocess.Popen(cmd, stdout=out, cwd=PROJECT_ROOT)

        start_time = time.time()
        monitor_thread = threading.Thread(
            target=monitor_stream,
            args=(phase, stream_file, process, start_time),
            daemon=True,
        )
        monitor_thread.start()

        exit_code = process.wait()
        monitor_thread.join(timeout=5)

        if exit_code != 0:
            print()
            print(f"Error: Agent failed in phase: {phase}")
            print(f"Log pruefen: {log_file}")
            print(f"Branch: {branch} (Zwischenzustand)")
            sys.exit(1)
    finally:
        try:
            os.unlink(stream_file)
        except OSError:
            pass


# --- Log parsing ---


def parse_verdict(log_file: Path) -> str:
    """Read the log file and return the last Verdict value."""
    content = (PROJECT_ROOT / log_file).read_text()
    matches = re.findall(r"^Verdict:\s*(\S+)", content, re.MULTILINE)
    return matches[-1] if matches else ""


def extract_between(content: str, start_marker: str, end_marker: str) -> list[str]:
    """Extract all text blocks between start/end markers."""
    blocks = []
    in_block = False
    current = []
    for line in content.splitlines():
        if start_marker in line:
            in_block = True
            current = []
            continue
        if end_marker in line:
            in_block = False
            if current:
                blocks.append("\n".join(current))
            continue
        if in_block and line.strip():
            current.append(line)
    return blocks


def extract_scoped_discussion(content: str, review_round: int) -> str:
    """Extract DISCUSSION items scoped to a specific review round."""
    lines = content.splitlines()
    in_scope = False
    in_discussion = False
    items = []
    for line in lines:
        if re.match(rf"^## REVIEW {review_round}\b", line):
            in_scope = True
            continue
        if in_scope and re.match(r"^## ", line) and not re.match(rf"^## REVIEW {review_round}\b", line):
            break  # Next section
        if in_scope and "<!-- DISCUSSION_START -->" in line:
            in_discussion = True
            continue
        if in_scope and "<!-- DISCUSSION_END -->" in line:
            in_discussion = False
            continue
        if in_discussion and line.strip():
            items.append(line)
    return "\n".join(items)


# --- Phase functions ---


def phase_implement(
    platform: str, ticket_file: Path, log_file: Path, branch: str,
) -> None:
    print()
    print("=== IMPLEMENT ===")
    prompt = (
        f"Implementiere dieses Ticket fuer die {platform} Plattform.\n\n"
        f"Ticket-Datei: {ticket_file}\n"
        f"Implementation-Log: {log_file}\n\n"
        f"Lies zuerst das Ticket, dann implementiere es.\n"
        f"Wenn du fertig bist, haenge deinen Abschnitt an das Implementation-Log an "
        f"(siehe Agent-Instruktionen fuer Format)."
    )
    cmd = [
        "claude", "-p", prompt,
        "--agent", "ticket-implementer",
        "--no-session-persistence",
        "--verbose",
        "--output-format", "stream-json",
        "--max-turns", str(MAX_TURNS_IMPLEMENT),
        "--allowedTools", build_tools_arg(IMPLEMENTER_TOOLS),
    ]
    run_agent("IMPLEMENT", cmd, log_file, branch)

    content = (PROJECT_ROOT / log_file).read_text()
    if "## IMPLEMENT" not in content:
        print("Error: Implementer hat keinen IMPLEMENT-Abschnitt ins Log geschrieben.")
        print(f"Moeglicherweise max-turns erreicht (aktuell: {MAX_TURNS_IMPLEMENT}). Log pruefen: {log_file}")
        sys.exit(1)
    if "CHALLENGES_START" not in content:
        print("Warning: IMPLEMENT-Abschnitt enthaelt keine Challenges-Marker.")


def phase_review(
    review_round: int, platform: str, ticket_id: str,
    ticket_file: Path, log_file: Path, branch: str,
) -> str:
    print()
    print(f"=== REVIEW ({review_round}/{MAX_REVIEWS}) ===")
    prompt = (
        f"Reviewe die Aenderungen auf Branch {branch} fuer Ticket {ticket_id} ({platform}).\n\n"
        f"Ticket-Datei: {ticket_file}\n"
        f"Implementation-Log: {log_file}\n"
        f"Review-Runde: {review_round}\n\n"
        f"Lies zuerst das Implementation-Log fuer den bisherigen Verlauf, dann reviewe die Aenderungen.\n"
        f"Haenge deinen Review-Abschnitt an das Implementation-Log an "
        f"(siehe Agent-Instruktionen fuer Format)."
    )
    cmd = [
        "claude", "-p", prompt,
        "--agent", "ticket-reviewer",
        "--no-session-persistence",
        "--verbose",
        "--output-format", "stream-json",
        "--max-turns", str(MAX_TURNS_REVIEW),
        "--allowedTools", build_tools_arg(REVIEWER_TOOLS),
    ]
    run_agent(f"REVIEW {review_round}", cmd, log_file, branch)

    verdict = parse_verdict(log_file)
    print(f"Verdict: {verdict}")

    if not verdict:
        print("Error: Kein Verdict in Log gefunden. Reviewer hat Log nicht korrekt geschrieben.")
        print(f"Moeglicherweise max-turns erreicht (aktuell: {MAX_TURNS_REVIEW}). Log pruefen: {log_file}")
        sys.exit(1)
    if verdict not in ("PASS", "FAIL"):
        print(f"Error: Ungueltiges Verdict '{verdict}' (erwartet: PASS oder FAIL)")
        sys.exit(1)

    return verdict


def collect_discussion(log_file: Path, review_round: int, discussion_file: Path, ticket_id: str) -> None:
    """Extract DISCUSSION items from the current review round and append to discussion file."""
    content = (PROJECT_ROOT / log_file).read_text()
    discussion = extract_scoped_discussion(content, review_round)
    if not discussion:
        return

    full_path = PROJECT_ROOT / discussion_file
    full_path.parent.mkdir(parents=True, exist_ok=True)
    if not full_path.is_file():
        full_path.write_text(
            f"# Discussion Items: {ticket_id}\n\n"
            f"Gesammelt waehrend automatischem Review. Zum spaeteren Abarbeiten.\n\n"
        )
    with open(full_path, "a") as f:
        f.write(f"## Review-Runde {review_round}\n\n")
        f.write(discussion + "\n\n")


def phase_fix(
    fix_round: int, platform: str, ticket_id: str,
    ticket_file: Path, log_file: Path, branch: str,
) -> None:
    print()
    print(f"=== FIX ({fix_round}) ===")
    prompt = (
        f"Fixe die BLOCKER-Findings aus dem letzten Review fuer Ticket {ticket_id} ({platform}).\n\n"
        f"Implementation-Log: {log_file}\n"
        f"Ticket-Datei: {ticket_file}\n\n"
        f"Lies das Implementation-Log fuer den vollstaendigen Verlauf und die BLOCKER-Findings.\n"
        f"Haenge deinen Fix-Abschnitt an das Implementation-Log an "
        f"(siehe Agent-Instruktionen fuer Format)."
    )
    cmd = [
        "claude", "-p", prompt,
        "--agent", "ticket-implementer",
        "--no-session-persistence",
        "--verbose",
        "--output-format", "stream-json",
        "--max-turns", str(MAX_TURNS_FIX),
        "--allowedTools", build_tools_arg(IMPLEMENTER_TOOLS),
    ]
    run_agent(f"FIX {fix_round}", cmd, log_file, branch)

    content = (PROJECT_ROOT / log_file).read_text()
    if f"## FIX {fix_round}" not in content:
        print(f"Error: Implementer hat keinen FIX {fix_round}-Abschnitt ins Log geschrieben.")
        print(f"Moeglicherweise max-turns erreicht (aktuell: {MAX_TURNS_FIX}). Log pruefen: {log_file}")
        sys.exit(1)


def phase_close(ticket_id: str, log_file: Path, branch: str) -> None:
    print()
    print("=== CLOSE ===")
    prompt = (
        f"Nutze /close-ticket fuer Ticket {ticket_id}.\n\n"
        f"Implementation-Log: {log_file}\n"
        f"Haenge deinen CLOSE-Abschnitt an das Implementation-Log an "
        f"(siehe Agent-Instruktionen fuer Format)."
    )
    cmd = [
        "claude", "-p", prompt,
        "--agent", "ticket-implementer",
        "--no-session-persistence",
        "--verbose",
        "--output-format", "stream-json",
        "--max-turns", str(MAX_TURNS_CLOSE),
        "--allowedTools", build_tools_arg(IMPLEMENTER_TOOLS),
    ]
    run_agent("CLOSE", cmd, log_file, branch)

    content = (PROJECT_ROOT / log_file).read_text()
    if "## CLOSE" not in content:
        print("Error: Implementer hat keinen CLOSE-Abschnitt ins Log geschrieben.")
        print(f"Moeglicherweise max-turns erreicht (aktuell: {MAX_TURNS_CLOSE}). Log pruefen: {log_file}")
        sys.exit(1)


# --- Summary ---


def print_summary(
    branch: str, log_file: Path, discussion_file: Path,
) -> None:
    content = (PROJECT_ROOT / log_file).read_text()

    # Collect all challenges from IMPLEMENT and FIX sections
    challenges = extract_between(content, "<!-- CHALLENGES_START -->", "<!-- CHALLENGES_END -->")

    print()
    print("=== FERTIG ===")
    print(f"Branch: {branch}")
    print("Commits:")
    subprocess.run(["git", "log", f"main..{branch}", "--oneline"], cwd=PROJECT_ROOT)
    print(f"Log: {log_file}")

    if challenges:
        combined = "\n".join(challenges)
        if combined.strip() and combined.strip().lower() != "keine":
            print()
            print("Challenges:")
            for line in combined.splitlines():
                print(f"  {line}")

    if (PROJECT_ROOT / discussion_file).is_file():
        print()
        print("Discussion-Items zum spaeteren Abarbeiten:")
        print(f"  {discussion_file}")

    print()
    print("Naechste Schritte: Review + merge manuell")


# --- Main ---


def main() -> None:
    args = parse_args()
    ticket_id = args.ticket_id
    platform = detect_platform(ticket_id, args.platform)

    os.chdir(PROJECT_ROOT)

    # Preflight
    ticket_file = preflight_checks(ticket_id)
    print(f"Ticket: {ticket_file}")
    print(f"Platform: {platform}")

    # Platform suffix for shared tickets
    platform_suffix = f"-{platform}" if ticket_id.startswith("shared-") else ""

    # Paths
    branch = f"feature/{ticket_id}{platform_suffix}"
    log_file = Path(f"dev-docs/tickets/logs/{ticket_id}{platform_suffix}.md")
    discussion_file = Path(f"dev-docs/tickets/discussions/{ticket_id}{platform_suffix}.md")

    check_prior_run(branch, log_file, ticket_id)
    create_branch(branch)
    init_log(log_file, ticket_id, ticket_file, platform, branch)
    print(f"Log: {log_file}")

    # === IMPLEMENT ===
    phase_implement(platform, ticket_file, log_file, branch)

    # === REVIEW/FIX LOOP ===
    for i in range(1, MAX_REVIEWS + 1):
        verdict = phase_review(i, platform, ticket_id, ticket_file, log_file, branch)
        collect_discussion(log_file, i, discussion_file, ticket_id)

        if verdict == "PASS":
            print()
            print("=== Review bestanden ===")
            break

        if i == MAX_REVIEWS:
            print()
            print(f"=== ABBRUCH: {MAX_REVIEWS} Reviews ohne PASS ===")
            print(f"Findings im Log: {log_file}")
            sys.exit(1)

        phase_fix(i, platform, ticket_id, ticket_file, log_file, branch)

    # === CLOSE ===
    phase_close(ticket_id, log_file, branch)

    # === SUMMARY ===
    print_summary(branch, log_file, discussion_file)


if __name__ == "__main__":
    main()
