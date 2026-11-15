---
name: shell-hygiene-target-processes-by-pid
description: Signal only a process whose PID you started or confirmed, written as a literal number, never processes found by pattern, because a pattern matches the agent's own shell, other agents' sessions and the user's programs along with the one process meant. Covers what to run instead of `pkill`, `killall`, `pgrep -f <word> | xargs kill`, `kill $(pgrep ...)` and `lsof -ti :<port> | xargs kill`, keeping the PID when you start a process, confirming it with `ps -o pid,ppid,command -p <pid>` before `kill <pid>`, TERM before `-9`, and asking the user about a process you didn't start. Use whenever about to stop, restart, signal or look up a process, or free a port.
tags: [safety]
allowed-tools:
  - Bash
---

# Target processes by PID

_Signal only a PID you started or have confirmed, written as a literal
number, one at a time._

A process pattern matches every process whose name or command line
contains it, not the one you mean. On a machine where the user runs
editors, servers and several agent sessions, that set is larger than it
looks:

- `pgrep -f server` matches the agent's own shell, because the `bash -c`
  command line running it contains the word `server`.
- `pkill -f claude` or `pkill -f node` stops every agent session or every
  Node program the user has open.
- `lsof -ti :3000 | xargs kill` stops whatever holds the port, which may be
  the user's own dev server, not the one you started.

## Commands to avoid, and what to run instead

| Avoid                                                                                  | What it reaches                                        | Run instead                                                       |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------- |
| `pkill <name>`, `pkill -f <pattern>`                                                   | every process matching, the agent's own shell included | `kill <pid>` for the PID you started                              |
| `killall <name>`                                                                       | every process with that name, any user session         | `kill <pid>`                                                      |
| `kill $(pgrep ...)`, `kill $(cat <pidfile>)`, `kill "$PID"`, `pgrep ... \| xargs kill` | an unseen PID, possibly reused or matching too much    | look first, then `kill <pid>` with the literal number             |
| `lsof -ti :<port> \| xargs kill`                                                       | whatever holds the port                                | `lsof -i :<port>` to see who holds it; stop it only if it's yours |
| `kill -9 <pid>` as the first try                                                       | skips the process's cleanup                            | `kill <pid>` (TERM), then `-9` only if it ignores TERM            |
| `kill -- -<pgid>`, `kill 0`                                                            | a whole process group                                  | `kill <pid>`                                                      |

## Keep the PID when you start the process

```bash
my-server --port 3000 > "$scratch/my-server.log" 2>&1 &
echo $! > "$scratch/my-server.pid"  # or note it in your working state
```

`$scratch` stands for the session's scratch directory, where
`shell-hygiene-delete-named-paths` keeps temporary files. A background command started through the agent's own tool usually
returns a task or shell id; stop it through that tool rather than by
searching for it.

## Look first, then kill the number

Finding a process and signalling it are two separate commands. First
look, which only reads:

```bash
cat "$scratch/my-server.pid"
ps -o pid,ppid,user,etime,command -p 48213
```

Then, once the command line and start time are the ones you launched,
signal that PID by its number:

```bash
kill 48213
```

`kill` never interprets its targets: every target is a literal PID
number you have just looked at. No `$(cat my-server.pid)`, no
`$(pgrep -f server)`, no backticks, no `"$PID"` variable, no
`xargs kill`. Each of those signals a PID nobody saw, and a recorded PID
can be reused by an unrelated process once the original exits. Claude
Code deny rules may block any `kill` that contains `$` or a backtick for
that reason.

## When you didn't start it

Looking is fine: `pgrep -l <name>`, `ps aux | grep '[n]ame'` or
`lsof -i :<port>` list candidates without touching them. Show the user
the matching PIDs with their command lines and ask which, if any, to
stop.

## Enforcement

The `shell-hygiene` rulebook for
[CC Safety Net](https://github.com/kenryu42/claude-code-safety-net), in the
collection this skill came from, blocks `pkill`, `killall` and `xargs kill`.
It doesn't catch `kill $(pgrep -f ...)`, so that one is left to you. A block
reason tagged `[shell-hygiene/<rule>]` comes from that rulebook; take the
alternative it names rather than working around it.

## When to apply

- About to stop, restart or signal a process, or free a port.
- Cleaning up servers, watchers or test runs at the end of a task.
- A command hangs and you want to stop it.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-delete-named-paths`: keeping temporary files such as a PID file in the session's scratch directory, and deleting them by name.
