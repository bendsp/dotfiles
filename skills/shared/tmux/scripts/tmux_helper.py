#!/usr/bin/env python3
"""Small tmux helper for shared Codex and user workflows."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


FIELD_SEP = "\t"
DEFAULT_LINES = 40


@dataclass
class Pane:
    session_name: str
    window_index: str
    window_name: str
    pane_index: str
    pane_id: str
    pane_active: str
    window_active: str
    pane_title: str
    pane_current_command: str
    pane_current_path: str
    pane_dead: str
    pane_width: str
    pane_height: str

    @property
    def target(self) -> str:
        return f"{self.session_name}:{self.window_index}.{self.pane_index}"


def run_tmux(args: list[str], check: bool = True) -> str:
    cmd = ["tmux", *args]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if check and proc.returncode != 0:
        message = proc.stderr.strip() or proc.stdout.strip() or f"tmux failed: {' '.join(cmd)}"
        if "Operation not permitted" in message or "Permission denied" in message:
            message += (
                "\nTmux may still be running. Retry this read-only helper command "
                "with sandbox escalation."
            )
        raise SystemExit(message)
    return proc.stdout


def list_panes() -> list[Pane]:
    fmt = FIELD_SEP.join(
        [
            "#{session_name}",
            "#{window_index}",
            "#{window_name}",
            "#{pane_index}",
            "#{pane_id}",
            "#{pane_active}",
            "#{window_active}",
            "#{pane_title}",
            "#{pane_current_command}",
            "#{pane_current_path}",
            "#{pane_dead}",
            "#{pane_width}",
            "#{pane_height}",
        ]
    )
    output = run_tmux(["list-panes", "-a", "-F", fmt], check=True)
    panes: list[Pane] = []
    for raw_line in output.splitlines():
        if not raw_line.strip():
            continue
        parts = raw_line.split(FIELD_SEP)
        if len(parts) != 13:
            continue
        panes.append(Pane(*parts))
    return panes


def capture(target: str, lines: int) -> str:
    return run_tmux(["capture-pane", "-t", target, "-p", "-S", str(-lines)], check=True)


def resolve_target(query: str | None, panes: list[Pane]) -> Pane:
    if not panes:
        raise SystemExit("No tmux panes found.")

    if query is None or query == "":
        codex_matches = [pane for pane in panes if pane.window_name == "codex" or pane.pane_title == "codex"]
        if len(codex_matches) == 1:
            return codex_matches[0]
        raise SystemExit("No default target. Pass an explicit target or run setup-codex.")

    exact = [pane for pane in panes if query in {pane.target, pane.pane_id}]
    if len(exact) == 1:
        return exact[0]

    query_lower = query.lower()
    fuzzy = []
    for pane in panes:
        haystacks = [
            pane.window_name,
            pane.pane_title,
            pane.pane_current_command,
            pane.pane_current_path,
            pane.target,
            pane.pane_id,
        ]
        if any(query_lower in value.lower() for value in haystacks if value):
            fuzzy.append(pane)

    if len(fuzzy) == 1:
        return fuzzy[0]
    if not fuzzy:
        raise SystemExit(f"No pane matched '{query}'.")

    lines = ["Ambiguous target. Matches:"]
    for pane in fuzzy:
        lines.append(format_pane_line(pane))
    raise SystemExit("\n".join(lines))


def format_pane_line(pane: Pane) -> str:
    return (
        f"{pane.target} id={pane.pane_id} "
        f"window={pane.window_name!r} title={pane.pane_title!r} "
        f"cmd={pane.pane_current_command!r} path={pane.pane_current_path!r} "
        f"active={pane.pane_active}"
    )


def print_panes(panes: Iterable[Pane], json_mode: bool) -> None:
    if json_mode:
        print(json.dumps([asdict(pane) | {"target": pane.target} for pane in panes], indent=2))
        return
    for pane in panes:
        print(format_pane_line(pane))


def choose_session() -> str:
    output = run_tmux(
        ["list-sessions", "-F", "#{session_name}\t#{session_attached}\t#{session_last_attached}"],
        check=True,
    )
    sessions = []
    for line in output.splitlines():
        if not line.strip():
            continue
        name, attached, last_attached = line.split(FIELD_SEP)
        sessions.append((name, int(attached or "0"), int(last_attached or "0")))
    if not sessions:
        raise SystemExit("No tmux session found.")
    sessions.sort(key=lambda item: (item[1], item[2]), reverse=True)
    return sessions[0][0]


def get_window_target(session: str, window_name: str) -> str | None:
    output = run_tmux(["list-windows", "-t", session, "-F", "#{window_name}\t#{window_index}"], check=True)
    for line in output.splitlines():
        if not line.strip():
            continue
        name, index = line.split(FIELD_SEP)
        if name == window_name:
            return f"{session}:{index}"
    return None


def command_list(args: argparse.Namespace) -> int:
    print_panes(list_panes(), args.json)
    return 0


def command_snapshot(args: argparse.Namespace) -> int:
    panes = list_panes()
    if args.json:
        payload = []
        for pane in panes:
            payload.append(asdict(pane) | {"target": pane.target, "tail": capture(pane.target, args.lines)})
        print(json.dumps(payload, indent=2))
        return 0
    for pane in panes:
        print(f"=== {format_pane_line(pane)} ===")
        print(capture(pane.target, args.lines).rstrip())
        print()
    return 0


def command_capture(args: argparse.Namespace) -> int:
    pane = resolve_target(args.target, list_panes())
    print(capture(pane.target, args.lines), end="")
    return 0


def command_search(args: argparse.Namespace) -> int:
    panes = list_panes()
    hits = []
    pattern = args.pattern.lower()
    for pane in panes:
        tail = capture(pane.target, args.lines)
        matched_lines = [line for line in tail.splitlines() if pattern in line.lower()]
        if matched_lines:
            hits.append((pane, matched_lines))
    if args.json:
        payload = []
        for pane, matched_lines in hits:
            payload.append({"pane": asdict(pane) | {"target": pane.target}, "matches": matched_lines})
        print(json.dumps(payload, indent=2))
        return 0
    for pane, matched_lines in hits:
        print(f"=== {format_pane_line(pane)} ===")
        for line in matched_lines:
            print(line)
        print()
    if not hits:
        return 1
    return 0


def command_send(args: argparse.Namespace) -> int:
    pane = resolve_target(args.target, list_panes())
    if args.text:
        run_tmux(["send-keys", "-t", pane.target, "-l", args.text], check=True)
    if args.enter:
        run_tmux(["send-keys", "-t", pane.target, "Enter"], check=True)
    if args.show_tail:
        time.sleep(args.delay)
        print(capture(pane.target, args.lines), end="")
    return 0


def command_setup_codex(args: argparse.Namespace) -> int:
    session = args.session or choose_session()
    window_target = get_window_target(session, args.window_name)
    cwd = str(Path(args.cwd).expanduser().resolve()) if args.cwd else str(Path.home())

    if window_target is None:
        run_tmux(["new-window", "-d", "-t", session, "-n", args.window_name, "-c", cwd], check=True)
        window_target = get_window_target(session, args.window_name)
        if window_target is None:
            raise SystemExit("Failed to create codex window.")

    run_tmux(["select-pane", "-t", f"{window_target}.1", "-T", args.pane_title], check=False)
    panes = list_panes()
    pane = resolve_target(args.window_name, panes)

    if args.print_target_only:
        print(pane.target)
        return 0

    print(format_pane_line(pane))
    print(capture(pane.target, args.lines), end="")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="tmux helper for Codex.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List tmux panes.")
    list_parser.add_argument("--json", action="store_true", help="Print JSON.")
    list_parser.set_defaults(func=command_list)

    snapshot_parser = subparsers.add_parser("snapshot", help="Capture a tail from every pane.")
    snapshot_parser.add_argument("--lines", type=int, default=DEFAULT_LINES, help="Lines per pane.")
    snapshot_parser.add_argument("--json", action="store_true", help="Print JSON.")
    snapshot_parser.set_defaults(func=command_snapshot)

    capture_parser = subparsers.add_parser("capture", help="Capture a single pane.")
    capture_parser.add_argument("target", nargs="?", help="tmux target, pane id, title, or unique match.")
    capture_parser.add_argument("--lines", type=int, default=DEFAULT_LINES, help="Number of lines.")
    capture_parser.set_defaults(func=command_capture)

    search_parser = subparsers.add_parser("search", help="Search recent scrollback across panes.")
    search_parser.add_argument("pattern", help="Case-insensitive text to search for.")
    search_parser.add_argument("--lines", type=int, default=DEFAULT_LINES, help="Lines per pane.")
    search_parser.add_argument("--json", action="store_true", help="Print JSON.")
    search_parser.set_defaults(func=command_search)

    send_parser = subparsers.add_parser("send", help="Send literal text to a pane.")
    send_parser.add_argument("target", nargs="?", help="tmux target, pane id, title, or unique match.")
    send_parser.add_argument("--text", default="", help="Literal text to send.")
    send_parser.add_argument("--enter", action="store_true", help="Press Enter after sending text.")
    send_parser.add_argument("--show-tail", action="store_true", help="Print pane tail after sending.")
    send_parser.add_argument("--lines", type=int, default=20, help="Lines to print with --show-tail.")
    send_parser.add_argument("--delay", type=float, default=0.2, help="Seconds to wait before --show-tail.")
    send_parser.set_defaults(func=command_send)

    setup_parser = subparsers.add_parser("setup-codex", help="Create or reuse a dedicated Codex window.")
    setup_parser.add_argument("--session", help="Session name. Defaults to the most recently attached session.")
    setup_parser.add_argument("--window-name", default="codex", help="Window name to create or reuse.")
    setup_parser.add_argument("--pane-title", default="codex", help="Pane title to set.")
    setup_parser.add_argument("--cwd", help="Working directory for a newly created window.")
    setup_parser.add_argument("--lines", type=int, default=20, help="Lines of tail to print.")
    setup_parser.add_argument("--print-target-only", action="store_true", help="Only print the pane target.")
    setup_parser.set_defaults(func=command_setup_codex)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
