---
name: shell-hygiene-commands-as-cli-tools
description: Turn every command a project's agents and people run more than once into a documented command-line tool committed in the project, with command tokens, options and `--help`, a pure core with a thin shell, and tests, wired into the Nix dev shell as one command per entry point where the project uses Nix. Keeps that work out of the scratchpad, out of pasted pipelines and out of recipes in READMEs, AGENTS.md and skills, which name the command instead. Covers when a one-liner may stay inline, growing an existing tool rather than adding a script beside it, the tool's language, its layout and exit codes, and the dev shell entry. Use before writing a script or a multi-step shell command you or anyone will run again, before writing a recipe into documentation, when a scratchpad file is about to be run a second time, and when reviewing a repository's scripts, Makefile targets, dev shell commands or documented recipes.
---

# Commands as command-line tools

_A command worth running twice is worth a name. It goes in the project as a tool with commands and options, on the dev shell's `PATH`, and every document names it rather than spelling it out._

## The rule

1. **Run twice, make it a tool.** A command, pipeline or script that has run a second time, or that you, a later session or a person will run again, becomes a tool committed in the project, named for what it does, with a docstring or header saying what it does and how to call it. So does code that a committed file or claim rests on, even if it ran once: a script that built a committed file becomes a tool, and a probe behind a documented behaviour becomes a test or an eval example. A tool that isn't specific to the project goes in a skill's `scripts/` instead. None of it lives in the scratchpad, in a shell history, or as a block pasted from one reply to the next.
2. **Grow the tool that's there.** Before writing a new one, look for the project's existing tool, dev shell command, `Makefile` target or package script that does the job or nearly does. Add a command or an option to it rather than a script beside it. A project ends up with a few tools with many commands, not many one-purpose scripts.
3. **Documents name the command.** A README, `AGENTS.md`, `CLAUDE.md`, a skill, a CI workflow or a plan says `tool sync --dry-run`, never the five lines it runs. A recipe that a reader would copy is a tool that hasn't been written yet.
4. **The scratchpad holds data, not programs:** `coding-agent-scratchpad-scripts` says what may go there and how it's named.

A single command a reader understands at a glance (`git log --oneline -5`, `nix flake check`) stays inline. A check run once to answer a question, and an edit to a file, follow `coding-agent-scratchpad-scripts`.

## The tool's shape

- **Commands and options:** one executable per area of the project, with command tokens for its jobs (`tool prepare`, `tool run`, `tool report`) and named long options for every choice (`--parallel 2`, `--dry-run`), with no one-letter aliases, as `shell-hygiene-long-options` says. Positional arguments only for the thing acted on. No behaviour hidden in environment variables a reader can't see in `--help`.
- **`--help` at every level:** the tool and each command say what they do, their arguments and an example. The module's docstring, or the script's header, says the same.
- **Language:** the project's own language, so its tests, formatter and linters cover the tool. In a project without one, Python with the standard library, or a POSIX `sh` script when the tool only strings other commands together and stays under about 30 lines. Bash only through `writeShellApplication`, so its dependencies and `set -euo pipefail` are explicit.
- **A pure core and a thin shell:** parsing, deciding and formatting are functions over values; reading files, running commands, printing and exiting happen in a few shell functions around them. For Python, `python-hygiene-functional-style` gives the rules.
- **Tests:** the core has tests in the project's test suite, run by `nix flake check` where there is one. A tool that only prints a plan has a `--dry-run` or a test of the plan.
- **Behaviour:** output a person reads goes to stdout, diagnostics to stderr, and a `--json` option where another program reads it. Exit 0 on success, 1 on failure, 2 on bad usage, and any other code documented in `--help`. A command that changes things says what it will do with `--dry-run` and asks nothing interactively, so an agent can run it.
- **Layout:** in the project's usual place for tools, such as `tools/`, `scripts/` or a `cmd/` package, named for what it does (`release-notes`, `cross_repo_wave.py`), never `run.sh`, `helper.py` or `t2.py`.

## The dev shell

Where the project has a Nix dev shell:

- **One dev shell command per entry point,** with a lowercase category and a one-line `help`, as `nix-flakes` lays out, so `menu` lists it.
- **The tool lives in its own file,** read into the flake with `builtins.readFile`, `writeShellApplication` or the language's packaging, never written inline in a `''…''` string.
- **Its dependencies come from the dev shell,** so the tool runs the same for every agent and person. Nothing in the README says to install something globally.
- **`nix flake check` runs its tests.**

Where there's no Nix, the tool is still committed and named, and the README's development section lists it.

## Why and how to apply

**Why:** a pipeline pasted into a reply, or a script left in a scratchpad, is run once, read by nobody and rewritten slightly differently by the next session. A recipe in a README drifts from the code that should have replaced it. A tool with commands, options, `--help` and tests is found by `menu`, checked by CI, reviewed like code and improved in one place, so each session starts from the last one's work rather than from scratch.

**How to apply:** before writing a script or a multi-step command, ask whether it will run again. If not, run it inline. If so, find the project's tool for that area and add a command or option to it, or start one in the shape above, wire it into the dev shell, and test its core. Before writing a recipe into a document, write the tool and name it instead. When reviewing, list every pasted recipe, scratchpad program and one-purpose script, and fold each into a tool.

## When to apply

- About to write a script, or a shell command of more than one step, that will run again.
- About to run a scratchpad file a second time.
- About to write a command sequence into a README, `AGENTS.md`, a skill, a workflow or a plan.
- Reviewing a repository's scripts, `Makefile` targets, package scripts, dev shell commands or documented recipes.
- Briefing a subagent or headless run that will run commands: pass this rule on.

## Your preferences

!`cat "${CLAUDE_SKILL_DIR}/../shell-hygiene-commands-as-cli-tools.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/shell-hygiene-commands-as-cli-tools.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `shell-hygiene-commands-as-cli-tools.preferences.md` next to this skill's folder, then
`.agents/skills/shell-hygiene-commands-as-cli-tools.preferences.md` in the project. A project's
file overrides the user's, and the user's overrides this skill's defaults.

The keys this skill reads, with its own defaults:

```markdown
- Tools folder: the project's existing one; `tools/` in a project without one
- Fallback language: Python, standard library only
```

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `coding-agent-scratchpad-scripts`: what the scratchpad may hold and how its files are named, one-off checks run inline, edits through the edit tools, and never `source` a generated file.
- `shell-hygiene-long-options`: a command written into a script, document, skill or commit message, the tool's own options among them, uses each option's long form.
- `nix-flakes`: the dev shell's command discipline: categories, `help`, sorting, scripts in their own files.
- `python-hygiene-functional-style`: the pure core and thin shell, for a tool written in Python.
- `coding-agent-skill-references`: the preferences files this skill reads.
