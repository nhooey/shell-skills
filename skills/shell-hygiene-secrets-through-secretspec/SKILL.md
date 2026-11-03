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
  items by ID with their titles in the description, the user-global
  provider aliases that keep the vault out of every project, the user
  creating every credential, an SSH key loaded into a throwaway
  ssh-agent), and what to do when a read is refused or 1Password doesn't
  answer. Apply whenever a command,
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

What this skill says about SecretSpec itself is read from
`cachix/secretspec` at tag `v0.21.1`; each footnote cites the docs or
source there, and the rules with no footnote are conventions, with their
reasons beside them.

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
  without one (`Accessing secrets requires a reason`),[^require-reason]
  and records it in the audit log.[^audit-reason] Say what the command does and why, in a few words, with
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

## The user-global provider aliases

SecretSpec reads a user-global config at `~/.config/secretspec/config.toml`,
on macOS as well as Linux.[^global-path][^macos-path] Its
`[defaults.providers]` table declares provider aliases that every
project's manifest can name in a secret's `providers`,[^user-aliases] and
an alias can carry a `cache`, a faster local store that answers until
`max_age` runs out.[^alias-cache] Declare the 1Password vault there once,
as two aliases, so no project holds its ID:

```toml
# ~/.config/secretspec/config.toml
[defaults.providers.onepassword]
uri = "onepassword://<vault-id>"
cache = { provider = "keyring://", max_age = "8h" }

[defaults.providers.onepassword-uncached]
uri = "onepassword://<vault-id>"
```

| Alias                  | Cache                       | For                                                        |
| ---------------------- | --------------------------- | ---------------------------------------------------------- |
| `onepassword`          | login keychain, 8 hours     | read-only credentials, so 1Password asks about once a day  |
| `onepassword-uncached` | none: 1Password asks always | credentials that can write, change settings or act as root |

- **A project declares no `[providers]` of these names.** A project alias
  of the same name wins over the user-global one,[^alias-precedence] so a
  copy in a project keeps the vault ID there and stops following the
  global one.
- **Keep the file in the user's Home Manager config.** Generated, it is
  a read-only link, and `secretspec config global init` and
  `secretspec config global provider add`, which write
  it,[^cli-writes-global] fail on it: change the config and switch. Ask
  before changing it either way: it is the user's, shared by every
  project.

## Writing a `secretspec.toml`

```toml
[project]
name = "github-config"
revision = "1.0"

[profiles.default]
GITHUB_TOKEN = { description = "Fine-grained token: Administration and Contents read-only (1Password: GitHub Token (FGPAT): github-config-plan)", required = true, providers = ["onepassword"], ref = { item = "<item-id>", field = "token" } }

[profiles.apply]
GITHUB_TOKEN = { description = "Fine-grained token: Administration read and write (1Password: GitHub Token (FGPAT): github-config-apply)", required = true, providers = ["onepassword-uncached"], ref = { item = "<item-id>", field = "token" } }
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
- **1Password items by ID**, so renaming the item doesn't break the
  manifest. The vault comes from the alias's URI, which names a vault
  only.[^uri-vault-only]
- **The item's title in `description`**, after `1Password:`, so a reader
  finds the item without a lookup.
- **The field by its label**, such as `token` or `private key`. Without
  `field`, SecretSpec reads the item's value or password
  field.[^ref-field]
- **Commit it.** The manifest names secrets and item IDs, not values or
  the vault.
- **The user creates every credential.** SecretSpec never creates an
  item through a `ref`,[^ref-no-create] and an agent doesn't either, with
  `op` or otherwise. The user makes the item in 1Password, an SSH key
  with **New Item, SSH Key, Generate** or
  `op item create --category "SSH Key" --ssh-generate-key ed25519` in
  their own terminal; the agent then finds its ID with `op item list`,
  which shows no values, and writes the `ref`.
- **`secretspec` from `PATH`.** A keychain cache entry trusts only the
  `secretspec` build that wrote it, so a project that packages its own
  build makes macOS ask again. Use the one on `PATH`.

## An SSH private key

1Password returns an SSH Key item's `private key` field in PKCS#8 form,
which `ssh-add` reads as it is. Load it into a throwaway agent that ends
with the script, so no key file is left behind:

```bash
eval "$(ssh-agent -s)" >/dev/null
trap 'ssh-agent -k >/dev/null' EXIT
secretspec get --reason "router-ssh: log in to the router" ROUTER_SSH_KEY | ssh-add -q -
ssh root@192.168.8.1
```

The public key goes on the server: `op item get <item-id> --fields "public key"`
prints it, and it is safe to show.

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
[^alias-cache]: [caching.mdx line 34, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/concepts/providers/caching.mdx?plain=1#L34-L34), unchanged since v0.20.0
[^alias-precedence]: [providers.mdx line 195, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/concepts/providers.mdx?plain=1#L195-L195), unchanged since v0.18.0
[^audit-reason]: [audit.md line 79, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/concepts/audit.md?plain=1#L79-L79), unchanged since v0.12.0
[^cli-writes-global]: [providers.mdx line 247, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/concepts/providers.mdx?plain=1#L247-L247), unchanged since v0.18.0
[^global-path]: [config.rs line 2925, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/secretspec/src/config.rs#L2925-L2925), unchanged since v0.7.2
[^macos-path]: [config.rs line 2978, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/secretspec/src/config.rs#L2978-L2978), unchanged since v0.7.2
[^ref-field]: [onepassword.mdx line 165, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/providers/onepassword.mdx?plain=1#L165-L165), unchanged since v0.18.0
[^ref-no-create]: [onepassword.mdx line 173, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/providers/onepassword.mdx?plain=1#L173-L173), unchanged since v0.18.0
[^require-reason]: [configuration.mdx line 83, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/reference/configuration.mdx?plain=1#L83-L83), unchanged since v0.20.0
[^uri-vault-only]: [onepassword.mdx line 120, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/providers/onepassword.mdx?plain=1#L120-L120), unchanged since v0.18.0
[^user-aliases]: [providers.mdx line 191, v0.21.1](https://github.com/cachix/secretspec/blob/v0.21.1/docs/src/content/docs/concepts/providers.mdx?plain=1#L191-L191), unchanged since v0.18.0
