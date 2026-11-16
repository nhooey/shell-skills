"""Tests for tools/rulebook.py's argument parsing and pure core."""

import contextlib
import io
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import rulebook  # noqa: E402


def deny(reason):
    return json.dumps(
        {
            "hookSpecificOutput": {
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }
    )


BOOK = {
    "name": "hygiene",
    "rules": [{"name": "pkill"}, {"name": "killall"}],
    "tests": [
        {"command": "pkill -f x", "expect": "blocked", "rule": "pkill"},
        {"command": "kill 123", "expect": "allowed"},
    ],
}


class ParseArgs(unittest.TestCase):
    def test_plugin_after_command(self):
        args = rulebook.parse_args(["test", "--plugin", "p", "a.json", "b.json"])
        self.assertEqual(
            (args.command, args.plugin, args.rulebooks),
            ("test", "p", ["a.json", "b.json"]),
        )

    def test_plugin_after_command_overrides_one_before(self):
        self.assertEqual(
            rulebook.parse_args(
                ["--plugin", "pinned", "test", "--plugin", "mine"]
            ).plugin,
            "mine",
        )

    def test_plugin_before_command_is_kept(self):
        args = rulebook.parse_args(["--plugin", "pinned", "test"])
        self.assertEqual((args.plugin, args.rulebooks), ("pinned", []))

    def usage_error(self, argv):
        with (
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaises(SystemExit) as raised,
        ):
            rulebook.parse_args(argv)
        return raised.exception.code

    def test_missing_plugin_is_usage_error(self):
        self.assertEqual(self.usage_error(["test"]), 2)

    def test_missing_command_is_usage_error(self):
        self.assertEqual(self.usage_error(["--plugin", "p"]), 2)

    def test_unknown_command_is_usage_error(self):
        self.assertEqual(self.usage_error(["--plugin", "p", "lint"]), 2)


class UncoveredRules(unittest.TestCase):
    def test_lists_rules_without_a_blocked_fixture(self):
        self.assertEqual(rulebook.uncovered_rules(BOOK), ["killall"])

    def test_allowed_fixture_does_not_cover(self):
        book = {
            "rules": [{"name": "r"}],
            "tests": [{"command": "c", "expect": "allowed", "rule": "r"}],
        }
        self.assertEqual(rulebook.uncovered_rules(book), ["r"])


class Decision(unittest.TestCase):
    def test_empty_output_allows(self):
        self.assertEqual(rulebook.decision(""), ("allow", ""))

    def test_reads_deny_and_reason(self):
        self.assertEqual(rulebook.decision(deny("Rule: x")), ("deny", "Rule: x"))


class Judge(unittest.TestCase):
    blocked = {"command": "pkill -f x", "expect": "blocked", "rule": "pkill"}
    allowed = {"command": "kill 1", "expect": "allowed"}

    def test_blocked_by_its_rule_passes(self):
        self.assertIsNone(
            rulebook.judge(
                "hygiene", self.blocked, deny("Blocked\nRule: custom.hygiene/pkill")
            )
        )

    def test_blocked_but_allowed_fails(self):
        self.assertEqual(
            rulebook.judge("hygiene", self.blocked, ""),
            "[pkill -f x] expected blocked by pkill, was allowed",
        )

    def test_blocked_by_another_rule_fails(self):
        self.assertEqual(
            rulebook.judge("hygiene", self.blocked, deny("Rule: builtin/rm")),
            "[pkill -f x] expected blocked by pkill, got: Rule: builtin/rm",
        )

    def test_rule_name_must_match_whole_line(self):
        self.assertIsNotNone(
            rulebook.judge(
                "hygiene", self.blocked, deny("Rule: custom.hygiene/pkill-all")
            )
        )

    def test_allowed_passes_when_not_denied(self):
        self.assertIsNone(rulebook.judge("hygiene", self.allowed, ""))

    def test_allowed_but_denied_fails(self):
        self.assertEqual(
            rulebook.judge("hygiene", self.allowed, deny("Rule: custom.hygiene/kill")),
            "[kill 1] expected allowed, got: Rule: custom.hygiene/kill",
        )

    def test_unknown_expect_fails(self):
        self.assertEqual(
            rulebook.judge("hygiene", {"command": "c", "expect": "maybe"}, ""),
            "[c] unknown expect: maybe",
        )


class Failures(unittest.TestCase):
    def test_collects_coverage_and_fixture_failures(self):
        self.assertEqual(
            rulebook.failures(BOOK, ["", ""]),
            [
                "rule killall has no blocked fixture",
                "[pkill -f x] expected blocked by pkill, was allowed",
            ],
        )

    def test_rulebook_without_tests_fails(self):
        self.assertEqual(
            rulebook.failures({"name": "empty", "rules": []}, []),
            ["empty has no tests"],
        )


class HookInput(unittest.TestCase):
    def test_is_a_bash_pre_tool_use_call(self):
        payload = rulebook.hook_input("ls")
        self.assertEqual(
            (payload["hook_event_name"], payload["tool_name"], payload["tool_input"]),
            ("PreToolUse", "Bash", {"command": "ls"}),
        )


if __name__ == "__main__":
    unittest.main()
