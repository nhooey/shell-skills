# shell-skills

Coding-agent skills for shell commands that act only on what they name,
packaged as a Nix flake. Each skill is a directory under `skills/` with a
`SKILL.md`, its own `flake.nix` and `flake.lock`, built by
agent-skill-flake. `.cc-safety-net/rules/shell-hygiene/rulebook.json` holds
the CC Safety Net rules that enforce them.

## Build and test

- `nix develop`: enter the dev shell, which installs the dev-shell skills
  from `skills-devshell/` into `.agents/skills/`; `menu` lists its commands.
- `nix fmt`: nixfmt over `*.nix`, ruff over `*.py`, prettier over `*.md`
  and `*.yaml`.
- `rulebook test`: run the CC Safety Net rulebook's `tests` fixtures through
  the pinned plugin's hook (`tools/rulebook.py`). Add a fixture to the
  rulebook's `tests` for each rule or `block_args` entry you add.
- `nix flake check`: the treefmt check, a build of every skill package,
  `skill-citations verify` for each skill with a `citations.lock.json`,
  `rulebook test`, and `rulebook`'s unit tests in `tests/`.
- `skill-checks.toml`: read by agent-skill-flake's `skill-description`
  check. The skills in its `trigger-first` list under `[description]`
  open their description on "Load" and keep it within 500 characters.
