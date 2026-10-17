---
name: shell-hygiene-no-machine-wide-changes
description: |
  Keep changes inside the project. Ask before anything that changes the
  machine for every project and user: `sudo`, recursive `chmod` / `chown`
  outside the project, `brew upgrade` / `brew cleanup`, `npm -g` /
  `pip install` outside a virtualenv, `nix-collect-garbage -d`,
  `docker system prune`, `launchctl` / `systemctl`, `defaults write`, and
  edits to dotfiles or shell profiles. Use the project-local alternative:
  a dev shell, a virtualenv, a project config file. Apply whenever a
  command reaches outside the current project.
tags: [safety]
allowed-tools:
  - Bash
---

# shell-hygiene-no-machine-wide-changes

Some commands change state that every project, session and user on the
machine shares: installed packages, caches, services, permissions and
dotfiles. The task in front of you rarely needs that, and the change
outlives it. An upgrade breaks another project's pinned tool, a prune
deletes the cache a different session is building against, a dotfile
edit changes every shell the user opens.

The rule: **change only the project; ask before anything machine-wide.**

## How to load this skill

Passive reference. Loading it doesn't mean the user wants the machine
changed now — just that when a command reaches past the project, you'll
stop and ask.

## Commands to ask about first, and what to use instead

| Ask before                                                      | What it changes                             | Use instead                                                               |
| --------------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------- |
| `sudo ...`                                                      | anything, as root                           | the unprivileged way; ask if there isn't one                              |
| `chmod -R`, `chown -R` outside the project                      | permissions on shared paths                 | change the one file that needs it                                         |
| `brew upgrade`, `brew cleanup`, `brew install`                  | every project's Homebrew tools              | the project's dev shell or `nix shell`                                    |
| `npm install -g`, `pip install` outside a venv, `cargo install` | global tool versions                        | `npx`, a venv, the project's dev shell                                    |
| `nix-collect-garbage -d`, `nix store gc`                        | store paths other projects and sessions use | leave gc to the user                                                      |
| `docker system prune`, `docker volume prune`                    | every container, image and volume           | remove the containers you started, by id                                  |
| `launchctl`, `systemctl`, `brew services`                       | services for every session                  | run the service in the foreground for the task                            |
| `defaults write`, `git config --global`, `npm config set`       | settings for every program or repo          | project-local config                                                      |
| edits to `~/.zshrc`, `~/.bashrc`, `~/.config/...`, `~/.ssh/...` | every future shell or connection            | project files; on a declaratively managed machine, the user's config repo |

## When it's really needed

Say what the command changes beyond the project, why the task needs it,
and how to undo it, then run it only after the user agrees. On a machine
whose configuration is managed declaratively (Nix, Home Manager, a
dotfiles repo), the change belongs in that configuration, not in the
live system.

## Enforcement

This repo's [CC Safety Net](https://github.com/kenryu42/claude-code-safety-net)
rulebook, `.cc-safety-net/rules/shell-hygiene/rulebook.json`, blocks
recursive `chmod` / `chown`, Homebrew and global npm changes, Nix garbage collection, `docker ... prune`, service changes and `defaults write`. A block reason tagged `[shell-hygiene/<rule>]` comes from it;
take the alternative it names rather than working around it.

## When to apply

- About to install, upgrade or remove a tool outside the project.
- About to prune a cache, store, or container runtime.
- About to edit a file under `~` that isn't in the project.
- A command needs `sudo`.

## Related skills

Load each of these alongside this skill when it applies. If one isn't in
your skill listing, tell the user which skill is missing and ask whether
to install it from the same collection this skill came from; don't apply
it from memory.

- `shell-hygiene-symbolic-permission-modes`: how to write the mode once a permission change is agreed: `go-w`, not `755`.
