#!/usr/bin/env bash
# Run a CC Safety Net rulebook's own `tests` fixtures through the plugin's
# PreToolUse hook, as Claude Code runs it, and fail on any fixture whose
# outcome differs.
#
#   cc-safety-net-rulebook-fixtures.sh <plugin-dir> <rulebook.json>
#
# A `blocked` fixture passes only when the hook denies the command and names
# the fixture's rule (`custom.<rulebook>/<rule>`), so a deny from a built-in
# rule or from a different custom rule counts as a failure. An `allowed`
# fixture passes only when the hook does not deny. Every rule must have at
# least one `blocked` fixture.
set -euo pipefail

plugin=$1
rulebook=$2

name=$(jq -r .name "$rulebook")
home=$(mktemp -d)
mkdir -p "$home/rules/$name"
cp "$rulebook" "$home/rules/$name/rulebook.json"
jq -n --arg n "$name" '{version: 1, rules: [$n]}' >"$home/rules/rule.json"
export HOME=$home CC_SAFETY_NET_HOME=$home

hook() {
  jq -nc --arg c "$1" '{
    session_id: "check", transcript_path: "/tmp/check.jsonl",
    hook_event_name: "PreToolUse", tool_name: "Bash",
    tool_input: {command: $c}, cwd: "/tmp", permission_mode: "default"
  }' | node "$plugin/dist/bin/cc-safety-net.js" hook --coding-cli
}

failures=0
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

uncovered=$(jq -r '([.rules[].name] - [.tests[] | select(.expect == "blocked") | .rule])[]' "$rulebook")
for rule in $uncovered; do
  fail "rule $rule has no blocked fixture"
done

count=$(jq '.tests | length' "$rulebook")
[ "$count" -gt 0 ] || fail "$rulebook has no tests"

for ((i = 0; i < count; i++)); do
  command=$(jq -r ".tests[$i].command" "$rulebook")
  expect=$(jq -r ".tests[$i].expect" "$rulebook")
  rule=$(jq -r ".tests[$i].rule // empty" "$rulebook")
  output=$(hook "$command")
  [ -n "$output" ] || output='{}'
  decision=$(jq -r '.hookSpecificOutput.permissionDecision // "allow"' <<<"$output")
  reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason // ""' <<<"$output")
  case $expect in
  blocked)
    if [ "$decision" != deny ]; then
      fail "[$command] expected blocked by $rule, was allowed"
    elif ! grep -qxF "Rule: custom.$name/$rule" <<<"$reason"; then
      fail "[$command] expected blocked by $rule, got: $(grep '^Rule:' <<<"$reason")"
    fi
    ;;
  allowed)
    [ "$decision" != deny ] || fail "[$command] expected allowed, got: $(grep '^Rule:' <<<"$reason")"
    ;;
  *) fail "[$command] unknown expect: $expect" ;;
  esac
done

if [ "$failures" -gt 0 ]; then
  printf '%s: %d failures across %d fixtures\n' "$name" "$failures" "$count" >&2
  exit 1
fi
printf '%s: %d fixtures passed\n' "$name" "$count"
