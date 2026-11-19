---
name: shell-hygiene-delete-named-paths
description: Load before removing, overwriting or moving files or directories, such as with `rm`, `find -delete`, `rsync --delete`, `mv`, `cp` or `>`, or cleaning up after a task. Deletes named paths only, after a listing, never by glob or unchecked variable. Also load `macos-hygiene-trash-for-ad-hoc-deletes` for an ad-hoc delete on macOS and `git-hygiene-avoid-sweeping-operations` for deletes git makes.
tags: [safety]
allowed-tools:
  - Bash
---

# Delete named paths

_List first, then delete the paths you created, by name._

A deletion is only as narrow as its arguments. A glob expands to whatever
is there now, a variable can be empty or point somewhere unexpected, and
`find` matches more than you looked at. The user, another agent or a
generator may have put files in the same directory since you last
listed it, and `rm` has no undo.

## Commands to avoid, and what to run instead

| Avoid                                                           | What it reaches                                     | Run instead                                                   |
| --------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------- |
| `rm -rf "$DIR"/` or `rm -rf "$DIR/*"`                           | `/` or the working directory when `$DIR` is empty   | `rm -rf "${DIR:?}/name"`, which fails on an empty variable    |
| `rm -rf *`, `rm -rf .*`, `rm -rf ./*`                           | everything in the directory, others' files included | `ls`, then `rm` the named paths you created                   |
| `rm -rf ~/...`, `rm -rf /tmp/*`                                 | the user's files, other sessions' temp files        | delete your own paths; use the session's scratch directory    |
| `find ... -delete`, `find ... -exec rm`                         | every match, unseen                                 | run the same `find` with `-print` first, read it, then delete |
| `rsync --archive --delete src/ dst/` into an existing directory | every file in `dst` not in `src`                    | `rsync --dry-run --delete` to list first, or a fresh `dst`    |
| `mv` or `cp` over an existing path                              | the file already there                              | `mv -n` / `cp -n`, or check with `ls` first                   |
| `> file` on a file you didn't create                            | its contents                                        | write to a new path                                           |

The `rm`, `mv`, `cp`, `du` and `mktemp` options here stay short because
macOS's BSD builds have no long forms for them. Where GNU coreutils is the
tool that runs, write `rm --recursive --force`, `mv --no-clobber` and
`cp --no-clobber`.

## Keep what you create where you can find it

Put temporary files in the session's scratch directory, or one directory
you `mktemp -d` and record. Cleaning up is then `rm -rf` of that one
recorded path, not a search.

## When the user asks for a broad delete

Show the listing (`ls`, `find -print`, `du -sh`), say how many files and
how much space it covers, and delete only after they've seen it. "Clean
up" means the paths you created, not the directory.

## Enforcement

[CC Safety Net](https://github.com/kenryu42/claude-code-safety-net) blocks
`rm -rf` outside the working directory and `find -delete` on its own. The
`shell-hygiene` rulebook for it, in the collection this skill came from,
also blocks `rsync --delete`. A block reason tagged `[shell-hygiene/<rule>]`
comes from that rulebook; take the alternative it names rather than working
around it.

## When to apply

- About to run `rm`, `find -delete`, `rsync --delete`, or `mv`, `cp` or
  `>` onto an existing path.
- Cleaning up at the end of a task.
- Any delete whose path comes from a variable, a glob or a command's
  output.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `git-hygiene-avoid-sweeping-operations`: deletions git makes: `git clean`, `git restore .`, `git reset --hard`.
- `macos-hygiene-trash-for-ad-hoc-deletes`: on macOS, the files and folders you delete yourself outside repository code go to the Trash with `/usr/bin/trash`.
- `shell-hygiene-long-options`: writing commands with long options where the tool that runs has them.
