---
name: shell-hygiene-symbolic-permission-modes
description: |
  Write file permissions as symbolic modes, never octal numbers: `chmod
  u+x script.sh`, `chmod ug+rw shared.db`, `chmod go-w config`, not
  `chmod 755`, `chmod 644` or `chmod 0600`. A symbolic mode changes only
  the bits it names and reads as what it does; a number resets every bit,
  dropping ones you didn't mean to touch. The same goes for `install -m`,
  `mkdir -m`, `umask` and modes written in Nix, Dockerfiles, Ansible or
  scripts. Apply whenever about to set, change or describe a file mode.
tags: [safety]
allowed-tools:
  - Bash
---

# shell-hygiene-symbolic-permission-modes

An octal mode sets all twelve permission bits at once. `chmod 644 run.sh`
to make a file readable also clears its execute bit, and `chmod 755` on a
directory the user had kept group-writable takes that away. The number
also hides intent: a reader has to decode `0640` to learn it means "owner
reads and writes, group reads".

A symbolic mode names who, how and what — `u`, `g`, `o` or `a`; `+`, `-`
or `=`; `r`, `w`, `x`, `X`, `s`, `t` — and leaves every other bit as it
was.

The rule: **write the change you mean as a symbolic mode, `ug+rw`, never
as a number.**

## How to load this skill

Passive reference. Loading it doesn't mean the user wants permissions
changed now — just that when they are, you'll write the mode
symbolically.

## Numbers to avoid, and what to write instead

| Avoid                            | What it also does                                        | Write instead                                          |
| -------------------------------- | -------------------------------------------------------- | ------------------------------------------------------ |
| `chmod 755 script.sh`            | clears group and other write, sets bits you didn't check | `chmod u+x script.sh`, or `chmod a+x` if all may run   |
| `chmod 644 file`                 | clears every execute bit, setuid and sticky              | `chmod go-w file`, or `chmod a-x file` if that's meant |
| `chmod 600 key`                  | nothing extra, but reads as a number to decode           | `chmod go-rwx key`, or `chmod u=rw,go= key`            |
| `chmod 775 dir`, `chmod 664 f`   | resets owner and other bits along with group             | `chmod g+w dir`, `chmod ug+rw f`                       |
| `chmod 777 path`                 | opens it to every user                                   | the narrowest grant that works: `chmod g+w path`       |
| `chmod -R 755 dir`               | gives every file execute and resets every mode below     | `chmod -R u+rwX,go+rX dir` (`X`: dirs and executables) |
| `install -m 755`, `mkdir -m 700` | sets a number on create                                  | `install -m u=rwx,go=rx`, `mkdir -m u=rwx,go=`         |

When a new file needs an exact mode, `=` sets it in full and still reads
plainly: `chmod u=rw,g=r,o= app.conf`. Write `X`, not `x`, in a recursive
change: it adds execute only to directories and to files already
executable by someone, so directories stay traversable and plain files
don't become executable.

## Where numbers appear outside a shell

Use the symbolic form wherever the tool takes one: `install -m`,
`mkdir -m`, `umask u=rwx,g=rx,o=` in place of `umask 022`, Ansible's
`mode: "u=rw,g=r,o="`, and `RUN chmod u+x` in a Dockerfile. Where a format
only accepts a number, such as Nix's `mode = "0600"` or a Python
`os.chmod`, write the number with a comment giving its symbolic meaning,
`# u=rw,go=`.

## Describing a mode

When reporting a file's permissions, say them symbolically too: "owner
read-write, no access for group or other (`u=rw,go=`)", or quote
`ls -l`'s `-rw-------`, not `600`.

## When to apply

- About to run `chmod`, `install -m`, `mkdir -m` or `umask`.
- Writing a mode into a script, a Dockerfile, a config file or Nix.
- Explaining what a file's permissions are or should be.

## Related skills

Load each of these alongside this skill when it applies. If one isn't in
your skill listing, tell the user which skill is missing and ask whether
to install it from the same collection this skill came from; don't apply
it from memory.

- `shell-hygiene-no-machine-wide-changes`: recursive changes and permissions on paths outside the project.
