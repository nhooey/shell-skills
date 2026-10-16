---
name: shell-hygiene-delete-named-paths
description: |
  Never delete by glob, unchecked variable or whole tree: no
  `rm -rf "$DIR"/` with `$DIR` possibly empty, `rm -rf *`, `rm -rf ~/...`,
  `find ... -delete` or `-exec rm` without a listing first, or
  `rsync --delete` into a directory you didn't create. List what will go,
  then delete the paths you created, by name. Keep temporary files in the
  session's scratch directory. Apply whenever about to remove, overwrite or
  move files or directories.
tags: [safety]
allowed-tools:
  - Bash
---

# shell-hygiene-delete-named-paths

A deletion is only as narrow as its arguments. A glob expands to whatever
is there now, a variable can be empty or point somewhere unexpected, and
`find` matches more than you looked at. The user, another agent or a
generator may have put files in the same directory since you last
listed it, and `rm` has no undo.

The rule: **list first, then delete the paths you created, by name.**

## How to load this skill

Passive reference. Loading it doesn't mean the user wants anything
deleted now — just that when something is, you'll name it.

## Commands to avoid, and what to run instead

| Avoid                                                    | What it reaches                                     | Run instead                                                   |
| -------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------- |
| `rm -rf "$DIR"/` or `rm -rf "$DIR/*"`                    | `/` or the working directory when `$DIR` is empty   | `rm -rf "${DIR:?}/name"`, which fails on an empty variable    |
| `rm -rf *`, `rm -rf .*`, `rm -rf ./*`                    | everything in the directory, others' files included | `ls`, then `rm` the named paths you created                   |
| `rm -rf ~/...`, `rm -rf /tmp/*`                          | the user's files, other sessions' temp files        | delete your own paths; use the session's scratch directory    |
| `find ... -delete`, `find ... -exec rm`                  | every match, unseen                                 | run the same `find` with `-print` first, read it, then delete |
| `rsync -a --delete src/ dst/` into an existing directory | every file in `dst` not in `src`                    | `rsync -n --delete` to list first, or a fresh `dst`           |
| `mv` or `cp` over an existing path                       | the file already there                              | `mv -n` / `cp -n`, or check with `ls` first                   |
| `> file` on a file you didn't create                     | its contents                                        | write to a new path                                           |

## Keep what you create where you can find it

Put temporary files in the session's scratch directory, or one directory
you `mktemp -d` and record. Cleaning up is then `rm -rf` of that one
recorded path, not a search.

## When the user asks for a broad delete

Show the listing (`ls`, `find -print`, `du -sh`), say how many files and
how much space it covers, and delete only after they've seen it. "Clean
up" means the paths you created, not the directory.

## When to apply

- About to run `rm`, `find -delete`, `rsync --delete`, or `mv` / `cp` onto
  an existing path.
- Cleaning up at the end of a task.
- Any delete whose path comes from a variable, a glob or a command's
  output.
