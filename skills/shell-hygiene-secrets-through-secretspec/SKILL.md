---
name: shell-hygiene-secrets-through-secretspec
description: |
  Read every secret a command needs (a token, API key or password)
  through SecretSpec at the moment of use, with a reason: `secretspec get
  --reason "…" KEY` into one process's environment, or `secretspec run`.
  Never write a secret to a file, a `.env`, the dev shell, a command's
  arguments, a log or the reply, and never fetch it another way when
  SecretSpec fails. Covers when a checkout needs a `secretspec.toml` and
  when the user's general `gh` token is enough, writing one (a
  least-privilege token per profile, write access never cached, 1Password
  items by ID, a user-only alias for a public repo), and what to do when a
  read is refused or 1Password doesn't answer. Apply whenever a command,
  script or project needs a credential, a checkout has a
  `secretspec.toml`, a secret is about to go into an environment
  variable, file or dev shell, or a `secretspec` read fails.
tags: [safety]
allowed-tools:
  - Bash
---

# shell-hygiene-secrets-through-secretspec

A secret written anywhere outlives the command that needed it. A `.env`
file is read by every tool in the checkout and copied into backups; a
token exported in a dev shell's hook is saved by any tool that caches the
shell's environment; a token on a command line shows in `ps` and in shell
history; one printed in a reply is in the transcript for good.
[SecretSpec](https://secretspec.dev) lets a project declare the secrets it
needs in a committed `secretspec.toml`, and read each one from the user's
store, such as 1Password, only when a command runs. Each read is logged
to `~/.local/state/secretspec/audit.log` with its reason.

The rule: **a secret reaches a command only through SecretSpec, with a
reason, in that command's own environment, and goes nowhere else.**

## How to load this skill

Passive reference. Loading it doesn't mean a secret is needed now, just
that when one is, you'll read it this way.

## Reading a secret

```bash
# One value, into one process's environment:
GITHUB_TOKEN="$(secretspec get --reason "deploy: push the release tag" GITHUB_TOKEN)" \
  ./scripts/release.sh

# Every secret the profile declares, for one command:
secretspec run --reason "evals: run the periodic suite" -- npm run evals

# A narrower profile, and a manifest outside the current directory:
secretspec get --file "$root/secretspec.toml" --profile apply \
  --reason "github-config apply" GITHUB_TOKEN
```

- **A reason on every read.** SecretSpec refuses an AI agent's read
  without one (`Accessing secrets requires a reason`), and records it in
  the audit log. Say what the command does and why, in a few words, with
  no values: `"gh pr create in shell-skills"`, not `"need token"`. A
  script reads `SECRETSPEC_REASON` and falls back to a reason naming
  itself, so its caller can say more.
- **Into the environment, never the arguments.** Pass the value as an
  environment variable of the command that uses it. `--token "$TOKEN"`
  puts it in `ps` and in history.
- **At the moment of use.** Read it in the script or the command that
  needs it, not ahead of time in a shell you keep using.
- **Never shown.** Don't `echo` a secret, print it to check it worked, or
  quote it in a reply. Check a read by its effect: the command it was for
  succeeds.

## Where a secret never goes

| Never                                         | Why                                                                |
| --------------------------------------------- | ------------------------------------------------------------------ |
| A file: `.env`, a config file, a temp file    | Every tool and backup in reach reads it, and it outlives the run   |
| The dev shell: its hook, `.envrc`, `env` vars | Tools that cache the dev shell's environment save it to disk       |
| A command's arguments                         | Shown in `ps`, shell history and agent transcripts                 |
| A commit, a log or the reply                  | Permanent, and often mirrored or shared                            |
| `secretspec export` output kept anywhere      | It prints the resolved values; it is for piping into one tool only |

## Does this checkout need a `secretspec.toml`?

| The checkout needs                                              | Use                                                             |
| --------------------------------------------------------------- | --------------------------------------------------------------- |
| Nothing, or `gh` and `git` acting as the user                   | No manifest: the user's own `gh` login or token setup covers it |
| A secret its own scripts read, no more powerful than the user's | A `secretspec.toml` with one `default` profile                  |
| Different access for reading and for changing things            | A `secretspec.toml` with a profile per level of access          |

Secrets in GitHub Actions come from the repository's settings on GitHub,
not from SecretSpec on the user's machine; this skill doesn't cover them.

## Writing a `secretspec.toml`

```toml
[project]
name = "github-config"
revision = "1.0"

[providers]
onepassword = { uri = "onepassword://<vault-id>", cache = { provider = "keyring://", max_age = "8h" } }
onepassword-uncached = { uri = "onepassword://<vault-id>" }

[profiles.default]
GITHUB_TOKEN = { description = "Fine-grained token: Administration and Contents read-only", required = true, providers = ["onepassword"], ref = { item = "<item-id>", field = "token" } }

[profiles.apply]
GITHUB_TOKEN = { description = "Fine-grained token: Administration read and write", required = true, providers = ["onepassword-uncached"], ref = { item = "<item-id>", field = "token" } }
```

- **Least privilege.** One fine-grained token per project, scoped to what
  its scripts do, not the user's general token. Its `description` says
  what it can do.
- **A profile per level of access.** Reading is `default`; anything that
  can change things gets its own profile, used only by the commands that
  change things.
- **Write access is never cached.** A profile that can change things uses
  a provider with no `cache`, so the user approves every read; a
  read-only profile may cache, for hours rather than days.
- **1Password items by ID.** Vault and item IDs keep the manifest working
  when the user renames either.
- **Commit it.** The manifest names secrets, not values. In a public
  repository, keep the user's own vault and items out of it: name a
  user-only alias, `[defaults] providers = ["developer"]`, and let each
  user define `developer` under `[defaults.providers]` in
  `~/.config/secretspec/config.toml`. Ask before editing that file: it is
  the user's, shared by every project.
- **`secretspec` from `PATH`.** A keychain cache entry trusts only the
  `secretspec` build that wrote it, so a project that packages its own
  build makes macOS ask again. Use the one on `PATH`.

## When a read fails

| SecretSpec says                                    | Do                                                                          |
| -------------------------------------------------- | --------------------------------------------------------------------------- |
| `Accessing secrets requires a reason`              | Add `--reason "…"`, or set `SECRETSPEC_REASON` for a script                 |
| `promptError`, `authorization timeout` (1Password) | Ask the user to approve the 1Password prompt, then try once more            |
| `Failed to get secret` after an outage             | Tell the user; the 1Password app may need restarting                        |
| A macOS keychain prompt every time                 | Check that the `secretspec` on `PATH` is the one that wrote the cache entry |

Never work around a refused read: no `op read` of the same item, no
`gh auth token`, no copying the value from another tool's config. The
refusal is the user's control over the secret; fetching it another way
removes it. Don't retry in a loop either: each try is another prompt for
the user.

## When to apply

- A command, script or project needs a token, API key or password.
- A checkout has a `secretspec.toml`, or is about to get one.
- A secret is about to go into an environment variable, a file, the dev
  shell or a command line.
- A `secretspec` read fails.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-no-machine-wide-changes`: editing `~/.config/secretspec/config.toml` or other configuration shared by every project.
