#!/usr/bin/env bash
# capture.sh - source this to record real command transcripts as evidence.
#
#   source docs/evidence/tools/capture.sh
#   log_init docs/evidence/transcripts/m2-pytest.log
#   run 'pytest -v'
#   shot                      # renders docs/evidence/screenshots/m2-pytest.png
#
# Every command is written as "$ <command>" and then evaluated exactly as written; its real
# stdout+stderr is appended underneath. Nothing is edited afterwards - termshot.py renders
# the .log into a terminal-window PNG whose prompt (user@host) is read from this machine.

export TERM=xterm-256color   # real colour output, as in gnome-terminal
eval "$(dircolors -b)" 2>/dev/null
export PATH="$HOME/.local/bin:$HOME/.venvs/devops-tools/bin:$PATH"
export COLUMNS=140

EVIDENCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export EVIDENCE

_pretty_pwd() { pwd | sed "s|^$HOME|~|"; }

log_init() {           # log_init <logfile> [window-title]
    LOG="$(realpath -m "$1")"
    mkdir -p "$(dirname "$LOG")"
    : > "$LOG"
    [ -n "$2" ] && printf '#TITLE %s\n' "$2" >> "$LOG"
    printf '#CWD %s\n' "$(_pretty_pwd)" >> "$LOG"
}

log_cwd() { printf '#CWD %s\n' "$(_pretty_pwd)" >> "$LOG"; }

run() {                # run '<shell command>'
    local before="$PWD"
    printf '$ %s\n' "$1" >> "$LOG"
    eval "$1" >> "$LOG" 2>&1
    local rc=$?
    printf '\n' >> "$LOG"
    [ "$PWD" != "$before" ] && log_cwd
    return $rc
}

run_ok() { run "$1" || true; }   # for commands whose non-zero exit is expected

# render the transcript just recorded into docs/evidence/screenshots/
shot() {
    /usr/bin/python3 "$EVIDENCE/tools/termshot.py" "$LOG" "$EVIDENCE/screenshots"
}
