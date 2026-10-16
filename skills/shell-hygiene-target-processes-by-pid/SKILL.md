---
name: shell-hygiene-target-processes-by-pid
description: |
  Never find or stop processes by pattern: no `pkill`, `killall`,
  `pgrep -f <word> | xargs kill`, `kill $(pgrep ...)`, or
  `lsof -ti :<port> | xargs kill`. A pattern matches the agent's own shell,
  other agents' sessions and the user's programs along with the one process
  meant. Keep the PID of what you started, confirm it with
  `ps -o pid,ppid,command -p <pid>`, and signal that PID only. Apply
  whenever about to stop, restart, signal or look up a process, or free a
  port.
tags: [safety]
allowed-tools:
  - Bash
---

# shell-hygiene-target-processes-by-pid

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

The rule: **signal only a PID you started or have confirmed**, one at a
time.

## How to load this skill

Passive reference. Loading it doesn't mean the user wants a process
stopped now — just that when one is, you'll target it by PID.

## Commands to avoid, and what to run instead

| Avoid                                                   | What it reaches                                        | Run instead                                                       |
| ------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------- |
| `pkill <name>`, `pkill -f <pattern>`                    | every process matching, the agent's own shell included | `kill <pid>` for the PID you started                              |
| `killall <name>`                                        | every process with that name, any user session         | `kill <pid>`                                                      |
| `kill $(pgrep -f <pattern>)`, `pgrep ... \| xargs kill` | same as `pkill -f`                                     | `kill <pid>`                                                      |
| `lsof -ti :<port> \| xargs kill`                        | whatever holds the port                                | `lsof -i :<port>` to see who holds it; stop it only if it's yours |
| `kill -9 <pid>` as the first try                        | skips the process's cleanup                            | `kill <pid>` (TERM), then `-9` only if it ignores TERM            |
| `kill -- -<pgid>`, `kill 0`                             | a whole process group                                  | `kill <pid>`                                                      |

## Keep the PID when you start the process

```bash
my-server --port 3000 > /tmp/my-server.log 2>&1 &
echo $! > /tmp/my-server.pid        # or note it in your working state
```

A background command started through the agent's own tool usually
returns a task or shell id; stop it through that tool rather than by
searching for it.

## Confirm before signalling

```bash
ps -o pid,ppid,user,etime,command -p "$(cat /tmp/my-server.pid)"
```

Signal it only when the command line and start time are the ones you
launched. A recorded PID can be reused by an unrelated process once the
original exits.

## When you didn't start it

Looking is fine: `pgrep -l <name>`, `ps aux | grep '[n]ame'` or
`lsof -i :<port>` list candidates without touching them. Show the user
the matching PIDs with their command lines and ask which, if any, to
stop.

## Enforcement

This repo's [CC Safety Net](https://github.com/kenryu42/claude-code-safety-net)
rulebook, `.cc-safety-net/rules/shell-hygiene/rulebook.json`, blocks
`pkill`, `killall` and `xargs kill`. A block reason tagged `[shell-hygiene/<rule>]` comes from it;
take the alternative it names rather than working around it.

## When to apply

- About to stop, restart or signal a process, or free a port.
- Cleaning up servers, watchers or test runs at the end of a task.
- A command hangs and you want to stop it.
