# shell-skills

Coding-agent skills for shell commands that act only on what they name,
packaged as a Nix flake. Each skill is a directory under `skills/` with a
`SKILL.md`, its own `flake.nix` and `flake.lock`, built by
agent-skill-flake. `.cc-safety-net/rules/shell-hygiene/rulebook.json` holds
the CC Safety Net rules that enforce them.

## Build and test

- `nix develop`: enter the dev shell, which installs the dev-shell skills
  from `skills-devshell/` into `.agents/skills/`; `menu` lists its commands.
- `nix fmt`: nixfmt over `*.nix`, prettier over `*.md` and `*.yaml`.
- `nix flake check`: the treefmt check, a build of every skill package,
  `skill-citations verify` for each skill with a `citations.lock.json`, and
  the CC Safety Net rulebook's `tests` fixtures run through the plugin's hook
  by `tests/cc-safety-net-rulebook-fixtures.sh`. Add a fixture to the rulebook's
  `tests` for each rule or `block_args` entry you add.
