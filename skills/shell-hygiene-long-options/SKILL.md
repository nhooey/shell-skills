---
name: shell-hygiene-long-options
description: Write shell commands with long options where the tool has them, `rm --recursive --force`, `git push --force-with-lease`, `curl --silent --show-error --location`, not `-rf` or `-sSL`, so a reader sees what the command does. Covers commands an agent runs, commands shown to the user, and scripts and docs in repositories; checking a tool's `--help`, `man` page or a dry run before using a long option, since macOS's BSD `rm`, `cp`, `mv`, `ls`, `sed` and `find` lack them while GNU coreutils has them; when a repository script may use one (every platform it runs on has it, or its dev shell pins the tool); and the exceptions. Use whenever writing a shell command an agent will run or a person will read, or a script or doc in a repository.
tags: [style]
allowed-tools:
  - Bash
---

# Long options

_Spell out the option, `--recursive`, where the tool has a long form, so
the command says what it does._

`-rfv` and `-sSL` make the reader recall what each letter means for that
tool, and the same letter means different things to different tools.
`--recursive --force --verbose` and `--silent --show-error --location`
read as what they do, and a reviewer can check a command without opening
its manual.

## Where it applies

- Commands an agent runs.
- Commands shown to the user, in a reply or a suggestion.
- Scripts, Makefiles, CI files, dev shell commands and docs in a
  repository.

## Examples

| Short                         | Long                                            |
| ----------------------------- | ----------------------------------------------- |
| `rm -rfv build`               | `rm --recursive --force --verbose build` (GNU)  |
| `git push -f`                 | `git push --force-with-lease`                   |
| `curl -sSL "$url"`            | `curl --silent --show-error --location "$url"`  |
| `rsync -anv src/ dst/`        | `rsync --archive --dry-run --verbose src/ dst/` |
| `grep -rn pattern .`          | `grep --recursive --line-number pattern .`      |
| `mkdir -p a/b`                | `mkdir --parents a/b` (GNU)                     |
| `git commit -a -m "Subject"`  | `git commit --all --message "Subject"`          |
| `/usr/bin/trash -v -s <path>` | `/usr/bin/trash --verbose --stopOnError <path>` |

## Check that the tool has it

Long options differ by build, not only by tool:

- **BSD tools on macOS:** `/bin/rm`, `/bin/cp`, `/bin/mv`, `/bin/ls`,
  `/usr/bin/sed` and `/usr/bin/find` reject most long options
  (`rm: illegal option -- -`). macOS `/usr/bin/trash` has its own:
  `--verbose`, `--stopOnError`.
- **GNU coreutils:** has them, and is what a Nix dev shell or a Linux
  machine usually puts on the `PATH`.

Before using a long option, check the tool that will actually run: its
`--help`, its `man` page, or a harmless run such as `--dry-run` or
`--version`. `command -v rm` shows which `rm` the `PATH` resolves to.

## In a repository

A script or doc in a repository runs wherever its users run it. Use a
long option there only when:

- every platform the script runs on has it, or
- the script's own dev shell pins the tool, as a Nix dev shell pinning
  GNU coreutils does, and the script runs inside it.

Otherwise keep the short option. Never add platform detection just to use
long options: a branch on `uname` costs more to read than the letters it
spells out.

## Exceptions

- An option with no long form in the tool that runs, such as `rm -r` with
  macOS's BSD `rm`.
- A common one-letter flag with no long form anywhere, such as `ssh -p`,
  `ssh -i` or `test -f`.

## Your preferences

!`cat "${CLAUDE_SKILL_DIR}/../shell-hygiene-long-options.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/shell-hygiene-long-options.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `shell-hygiene-long-options.preferences.md` next to this skill's
folder, then `.agents/skills/shell-hygiene-long-options.preferences.md` in
the project. A project's file overrides the user's, and the user's
overrides this skill's defaults.

## When to apply

- Writing a shell command to run, or to show the user.
- Writing or reviewing a script, Makefile, CI step, dev shell command or
  doc in a repository.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-delete-named-paths`: what a delete may name, with its example commands written in long options where the tool has them.
- `shell-hygiene-commands-as-cli-tools`: a command run twice becomes a committed tool, whose own options follow this skill.
