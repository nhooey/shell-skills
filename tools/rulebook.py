"""Work with this repository's CC Safety Net rulebooks.

Commands:

  rulebook [--plugin DIR] test [--plugin DIR] [--transparent-wrapper CMD ...]
                                [RULEBOOK ...]
      Run each rulebook's own `tests` fixtures through the plugin's
      PreToolUse hook, as Claude Code runs it, and fail on any fixture whose
      outcome differs. With no RULEBOOK, tests every
      `.cc-safety-net/rules/*/rulebook.json` under the current directory.
      Each --transparent-wrapper names a command, such as `nix`, written
      into the test config's `transparent_wrappers`, so the rulebook's rules
      also apply to a protected command run through it.

A `blocked` fixture passes only when the hook denies the command and names
the fixture's rule (`custom.<rulebook>/<rule>`), so a deny from a built-in
rule or from a different custom rule counts as a failure. An `allowed`
fixture passes only when the hook does not deny. Every rule must have at
least one `blocked` fixture.

Exit status: 0 when every fixture passes, 1 when any fails, 2 on bad usage.
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_GLOB = ".cc-safety-net/rules/*/rulebook.json"


# Pure core


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="rulebook",
        description="Work with this repository's CC Safety Net rulebooks.",
        epilog="Example: rulebook test .cc-safety-net/rules/shell-hygiene/rulebook.json",
    )
    parser.add_argument(
        "--plugin",
        metavar="DIR",
        help="CC Safety Net plugin checkout holding dist/bin/cc-safety-net.js "
        "(the dev shell's `rulebook` passes the pinned one)",
    )
    commands = parser.add_subparsers(dest="command", metavar="COMMAND", required=True)
    test = commands.add_parser(
        "test",
        help="run each rulebook's `tests` fixtures through the plugin's hook",
        description=(
            "Run each rulebook's `tests` fixtures through CC Safety Net's "
            "PreToolUse hook and fail on any fixture whose outcome differs. "
            "Exit 0 when all pass, 1 when any fails, 2 on bad usage."
        ),
        epilog="Example: rulebook test --plugin ./cc-safety-net",
    )
    test.add_argument(
        "--plugin",
        metavar="DIR",
        default=argparse.SUPPRESS,
        help="CC Safety Net plugin checkout; overrides a --plugin given "
        "before the command",
    )
    test.add_argument(
        "--transparent-wrapper",
        metavar="CMD",
        dest="transparent_wrappers",
        action="append",
        default=[],
        help="list CMD in the test config's `transparent_wrappers`, so a "
        "rule also applies to its command run through CMD; repeatable",
    )
    test.add_argument(
        "rulebooks",
        metavar="RULEBOOK",
        nargs="*",
        help=f"rulebook.json to test (default: every {DEFAULT_GLOB})",
    )
    args = parser.parse_args(argv)
    if args.plugin is None:
        parser.error("--plugin DIR is required outside the dev shell")
    return args


def uncovered_rules(rulebook):
    """Names of rules with no `blocked` fixture, in rulebook order."""
    covered = {
        test.get("rule")
        for test in rulebook.get("tests", [])
        if test.get("expect") == "blocked"
    }
    return [
        rule["name"]
        for rule in rulebook.get("rules", [])
        if rule["name"] not in covered
    ]


def config(name, transparent_wrappers):
    """The `rules/rule.json` that loads one rulebook, with any wrappers."""
    return {"version": 1, "rules": [name]} | (
        {"transparent_wrappers": list(transparent_wrappers)}
        if transparent_wrappers
        else {}
    )


def hook_input(command):
    """The PreToolUse payload Claude Code sends for a Bash call."""
    return {
        "session_id": "check",
        "transcript_path": "/tmp/check.jsonl",
        "hook_event_name": "PreToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": command},
        "cwd": "/tmp",
        "permission_mode": "default",
    }


def decision(output):
    """(permissionDecision, reason) from the hook's stdout; empty means allow."""
    specific = (json.loads(output) if output.strip() else {}).get(
        "hookSpecificOutput", {}
    )
    return (
        specific.get("permissionDecision", "allow"),
        specific.get("permissionDecisionReason", ""),
    )


def rule_line(reason):
    return next((line for line in reason.splitlines() if line.startswith("Rule:")), "")


def judge(name, fixture, output):
    """A failure message for one fixture given the hook's stdout, or None."""
    command, expect = fixture["command"], fixture["expect"]
    verdict, reason = decision(output)
    if expect == "blocked":
        rule = fixture.get("rule", "")
        if verdict != "deny":
            return f"[{command}] expected blocked by {rule}, was allowed"
        if f"Rule: custom.{name}/{rule}" not in reason.splitlines():
            return f"[{command}] expected blocked by {rule}, got: {rule_line(reason)}"
        return None
    if expect == "allowed":
        return (
            None
            if verdict != "deny"
            else f"[{command}] expected allowed, got: {rule_line(reason)}"
        )
    return f"[{command}] unknown expect: {expect}"


def failures(rulebook, outputs):
    """Every failure for a rulebook, given the hook's stdout per fixture."""
    found = [
        f"rule {rule} has no blocked fixture" for rule in uncovered_rules(rulebook)
    ]
    tests = rulebook.get("tests", [])
    if not tests:
        found.append(f"{rulebook['name']} has no tests")
    found += [
        message
        for fixture, output in zip(tests, outputs)
        if (message := judge(rulebook["name"], fixture, output)) is not None
    ]
    return found


# Shell


def run_hook(plugin, home, command):
    env = dict(os.environ, HOME=home, CC_SAFETY_NET_HOME=home)
    result = subprocess.run(
        [
            "node",
            str(Path(plugin) / "dist/bin/cc-safety-net.js"),
            "hook",
            "--coding-cli",
        ],
        input=json.dumps(hook_input(command)),
        capture_output=True,
        text=True,
        env=env,
        check=True,
    )
    return result.stdout


def test_rulebook(plugin, path, transparent_wrappers=()):
    rulebook = json.loads(Path(path).read_text())
    name = rulebook["name"]
    with tempfile.TemporaryDirectory() as home:
        rules = Path(home) / "rules"
        (rules / name).mkdir(parents=True)
        (rules / name / "rulebook.json").write_text(Path(path).read_text())
        (rules / "rule.json").write_text(json.dumps(config(name, transparent_wrappers)))
        outputs = [
            run_hook(plugin, home, test["command"])
            for test in rulebook.get("tests", [])
        ]
    found = failures(rulebook, outputs)
    count = len(rulebook.get("tests", []))
    for message in found:
        print(f"FAIL: {message}", file=sys.stderr)
    if found:
        print(f"{name}: {len(found)} failures across {count} fixtures", file=sys.stderr)
    else:
        print(f"{name}: {count} fixtures passed")
    return not found


def main(argv=None):
    args = parse_args(sys.argv[1:] if argv is None else argv)
    paths = args.rulebooks or sorted(str(p) for p in Path.cwd().glob(DEFAULT_GLOB))
    if not paths:
        print(
            f"rulebook: no rulebook given and none matches {DEFAULT_GLOB}",
            file=sys.stderr,
        )
        return 2
    results = [
        test_rulebook(args.plugin, path, args.transparent_wrappers) for path in paths
    ]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
