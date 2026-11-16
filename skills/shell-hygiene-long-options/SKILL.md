---
name: shell-hygiene-long-options
description: Write the long form of each option, `rm --recursive --force`, `curl --silent --show-error --location`, not `-rf` or `-sSL`, in every command written down for a later reader, in a script, Makefile, CI file, document, skill, commit message or a command suggested to the user, so the reader sees what it does; a one-off command typed in a session is exempt. Covers checking that the tool which runs has the long form, keeping the short option where it has none, as macOS's BSD `rm`, `cp`, `mv`, `ls`, `sed` and `find` don't, writing a repository script against the dev shell's GNU tool where it runs under one, and tools a repository writes taking long options only. Use whenever writing a command into a file, a commit message or a reply someone will reuse, or reviewing one.
tags: [style]
allowed-tools:
  - Bash
---

# Long options

_Spell out the option, `--recursive`, where the tool has a long form, so
a command written down says what it does._

`-rfv` and `-sSL` make the reader recall what each letter means for that
tool, and the same letter means different things to different tools.
`--recursive --force --verbose` and `--silent --show-error --location`
read as what they do, and a reviewer can check a command without opening
its manual.

## Where it applies

Anything a person will read later:

- Scripts, Makefiles, CI files and dev shell commands in a repository.
- Documents, READMEs, skills and plans.
- Commit messages and pull request descriptions.
- A command suggested to the user to run or keep.

A one-off command typed in a session, run once and read by nobody after,
is exempt.

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

## Where no long form exists

Long options differ by build, not only by tool. Check the tool that will
actually run: its `--help`, its `man` page, or a harmless run such as
`--version` or `--dry-run`; `command -v rm` shows which `rm` the `PATH`
resolves to.

Where that tool has no long form, the short option stays. These BSD tools
on macOS reject long options (`rm: illegal option -- -`), while their GNU
coreutils and findutils builds have them:

| macOS tool      | Write there | GNU long form                   |
| --------------- | ----------- | ------------------------------- |
| `/bin/rm`       | `rm -r -f`  | `rm --recursive --force`        |
| `/bin/cp`       | `cp -R -p`  | `cp --recursive --preserve`     |
| `/bin/mv`       | `mv -n`     | `mv --no-clobber`               |
| `/bin/ln`       | `ln -s`     | `ln --symbolic`                 |
| `/bin/mkdir`    | `mkdir -p`  | `mkdir --parents`               |
| `/bin/ls`       | `ls -a`     | `ls --all`                      |
| `/bin/chmod`    | `chmod -R`  | `chmod --recursive`             |
| `/usr/bin/sed`  | `sed -n -E` | `sed --quiet --regexp-extended` |
| `/usr/bin/cut`  | `cut -d ,`  | `cut --delimiter ,`             |
| `/usr/bin/find` | `find -L`   | none in GNU `find` either       |

macOS's `grep`, `sort`, `head`, `xargs` and `/usr/bin/trash` do take long
options.

A repository script that runs under a dev shell putting the GNU tools on
the `PATH`, as a Nix dev shell with coreutils does, is written against
those GNU tools, with their long options. A script that runs on the bare
machine keeps the short option where any of its platforms lacks the long
one. Never add platform detection just to use long options: a branch on
`uname` costs more to read than the letters it spells out.

A common one-letter flag with no long form anywhere, such as `ssh -p`,
`ssh -i` or `test -f`, stays as it is.

## Tools the repositories write

A command-line tool a repository writes takes long options only, as
`shell-hygiene-commands-as-cli-tools` says for its design: `--dry-run`,
`--parallel 2`, never a one-letter alias for them.

## Your preferences

!`cat "${CLAUDE_SKILL_DIR}/../shell-hygiene-long-options.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/shell-hygiene-long-options.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `shell-hygiene-long-options.preferences.md` next to this skill's
folder, then `.agents/skills/shell-hygiene-long-options.preferences.md` in
the project. A project's file overrides the user's, and the user's
overrides this skill's defaults.

## When to apply

- Writing a command into a script, Makefile, CI step, dev shell command,
  document, skill or commit message, or suggesting one to the user.
- Reviewing any of those.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-commands-as-cli-tools`: a command run twice becomes a committed tool, whose own options are long ones only.
- `shell-hygiene-delete-named-paths`: what a delete may name, with its example commands written in long options where the tool has them.
