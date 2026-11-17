# shell-skills

Coding-agent skills for shell commands that act only on what they name,
packaged as a Nix flake. Each skill is a directory under `skills/` with a
`SKILL.md`, its own `flake.nix` and `flake.lock`, built by
agent-skill-flake. The rulebooks in `.cc-safety-net/rules/` hold the CC
Safety Net rules that enforce them: `shell-hygiene` (`rulebook_version` 1)
and `shell-hygiene-secrets` (`rulebook_version` 2, for rules that need a
command path).

## Build and test

- `nix develop`: enter the dev shell, which installs the dev-shell skills
  from `skills-devshell/` into `.agents/skills/`; `menu` lists its commands.
- `nix fmt`: nixfmt over `*.nix`, ruff over `*.py`, prettier over `*.md`
  and `*.yaml`.
- `rulebook test --transparent-wrapper nix`: run each CC Safety Net
  rulebook's `tests` fixtures through the pinned plugin's hook
  (`tools/rulebook.py`), with `nix` as a transparent wrapper as the checks
  run them. Add a fixture to the rulebook's `tests` for each rule,
  `block_args` or `any_args` entry you add.
- `nix flake check`: the treefmt check, a build of every skill package,
  `skill-citations verify` for each skill with a `citations.lock.json`,
  `rulebook test`, and `rulebook`'s unit tests in `tests/`.
- `skill-checks.toml`: read by agent-skill-flake's `skill-description`
  check. The skills in its `trigger-first` list under `[description]`
  open their description on "Load" and keep it within 500 characters.
