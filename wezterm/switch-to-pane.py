#!/usr/bin/env python3
"""Switch to a specific WezTerm workspace and pane.

Usage:
    switch-to-pane.py <workspace> <pane_id>

Example:
    switch-to-pane.py "/Users/peter/work/mono-3" 68
    switch-to-pane.py "fully-sqlite" 112
"""
import sys
import base64
import os


def switch_to_pane(workspace: str, pane_id: int) -> None:
    """Send escape sequence to switch WezTerm workspace and activate pane."""
    value = f"{workspace}|{pane_id}"
    encoded = base64.b64encode(value.encode()).decode()
    seq = f"\033]1337;SetUserVar=switch_workspace_and_pane={encoded}\007"
    os.write(sys.stdout.fileno(), seq.encode())


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    workspace = sys.argv[1]
    try:
        pane_id = int(sys.argv[2])
    except ValueError:
        print(f"Error: pane_id must be an integer, got '{sys.argv[2]}'", file=sys.stderr)
        sys.exit(1)

    switch_to_pane(workspace, pane_id)


if __name__ == "__main__":
    main()
