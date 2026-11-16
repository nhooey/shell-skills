---
name: shell-hygiene-delete-named-paths
description: Delete only the paths you created, by name, after listing what will go. No deleting by glob, unchecked variable or whole tree: no `rm -rf "$DIR"/` with `$DIR` possibly empty, `rm -rf *`, `rm -rf ~/...`, `find ... -delete` or `-exec rm` without a listing first, `rsync --delete` into a directory you didn't create, or `mv`, `cp` or `>` over a file already there. Covers the narrower command for each, keeping temporary files in the session's scratch directory, moving an agent's own ad-hoc deletes on macOS to the Trash with `/usr/bin/trash` (never in repository code), and showing the user a broad delete before running it. Use whenever about to remove, overwrite or move files or directories.
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

## Ad-hoc deletes go to the Trash on macOS

When you delete something yourself on macOS, as cleanup during a session
rather than in code, move the named paths to the Trash, so the user can
still recover them:

```bash
/usr/bin/trash --verbose --stopOnError build/old-report.html notes.tmp
```

Don't use `rm` for these, and don't move files into `~/.Trash` by hand.
List first and name each path, as for any other delete.

Use `rm` on the named paths instead, and say which reason applies, when:

- **Space has to be reclaimed now:** large build outputs, or a full disk.
- **The path is throwaway:** it is in the session's scratch directory, or
  another throwaway directory you created.

This is for your own ad-hoc work only. Scripts, Makefiles, dev shell
commands and anything else committed to a repository stay portable: they
`rm` named paths as the rest of this skill says, and never detect macOS to
call `trash`.

On other systems, the rest of this skill applies unchanged.

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

- About to run `rm`, `find -delete`, `rsync --delete`, or `mv` / `cp` onto
  an existing path.
- Cleaning up at the end of a task, which on macOS goes to the Trash.
- Any delete whose path comes from a variable, a glob or a command's
  output.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `git-hygiene-avoid-sweeping-operations`: deletions git makes: `git clean`, `git restore .`, `git reset --hard`.
- `shell-hygiene-long-options`: writing commands with long options where the tool that runs has them.
