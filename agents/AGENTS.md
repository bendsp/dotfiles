My code and repos live in ~/Code.

Tmux is normally running. Use the tmux skill to inspect it; if its read-only discovery hits a socket permission error, retry with sandbox escalation instead of assuming there is no session.

`fd`, `bat`, and `delta` are installed globally. Use them when helpful, keeping output machine-readable for automation (`bat --plain --paging=never` and `git --no-pager` when parsing output).
