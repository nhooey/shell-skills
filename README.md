# shell-skills

Coding-agent skills for shell commands that act only on what they name,
packaged as a Nix flake.

An agent shares its machine with the user, other agent sessions and other
projects. A command that acts on everything matching a pattern — `pkill -f`,
`rm -rf *`, `brew upgrade` — reaches all of them, not just the one thing the
agent meant. Each skill here names those commands, what they reach, and the
narrower command to run instead.

Each skill is a self-contained directory under [`skills/`](skills/) with a
`SKILL.md` that an agent loads on demand. Skills are built by
[`agent-skill-flake`](https://github.com/nhooey/agent-skill-flake). Git
commands have their own skill,
[`git-hygiene-avoid-sweeping-operations`](https://github.com/nhooey/git-skills/tree/master/skills/git-hygiene-avoid-sweeping-operations)
in git-skills.

## Skills

| Skill                                                                                            | What it does                                                                                                       |
| ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| [`shell-hygiene-target-processes-by-pid`](skills/shell-hygiene-target-processes-by-pid/SKILL.md) | Signal only the PID you started or confirmed; no `pkill`, `killall`, `pgrep -f \| xargs kill` or port-based kills. |
| [`shell-hygiene-delete-named-paths`](skills/shell-hygiene-delete-named-paths/SKILL.md)           | List, then delete the paths you created by name; no globs, unchecked variables or unseen `find -delete`.           |
| [`shell-hygiene-no-machine-wide-changes`](skills/shell-hygiene-no-machine-wide-changes/SKILL.md) | Keep changes in the project; ask before `sudo`, global installs and upgrades, pruning, services and dotfiles.      |

## CC Safety Net rulebook

[`.cc-safety-net/rules/shell-hygiene/rulebook.json`](.cc-safety-net/rules/shell-hygiene/rulebook.json)
enforces these skills with
[CC Safety Net](https://github.com/kenryu42/claude-code-safety-net): it blocks
`pkill`, `killall`, `xargs kill`, `rsync --delete`, recursive `chmod` / `chown`,
Homebrew and global npm changes, Nix garbage collection, `docker ... prune`,
service changes and `defaults write`, on top of CC Safety Net's built-in `rm`
and `find -delete` rules. `sudo` can't be blocked from a rulebook, because CC
Safety Net analyzes the command it wraps.

```bash
cc-safety-net rule add nhooey/shell-skills --only shell-hygiene --global
```

## Install

```bash
# Preview what installing every skill would change, without writing anything
nix run github:nhooey/shell-skills#preview

# Install all skills into the agent's skill directory
nix run github:nhooey/shell-skills#install
```

Package outputs:

- `agent-skills-nhooey-shell-all` — the aggregate of every skill (also `default`)
- `agent-skill-nhooey-shell-hygiene-target-processes-by-pid`
- `agent-skill-nhooey-shell-hygiene-delete-named-paths`
- `agent-skill-nhooey-shell-hygiene-no-machine-wide-changes`

## Development

```bash
nix develop      # enter the dev shell; run `menu` to list commands
nix fmt          # nixfmt over *.nix, prettier over *.md / *.yaml
nix flake check  # runs the treefmt check (fails on any unformatted file)
```
