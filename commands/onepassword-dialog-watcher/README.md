# onepassword-dialog-watcher

Plays a sound and sends a macOS notification only while a 1Password approval dialog is on screen, whichever client asked: SSH signing, `op`, SecretSpec or a terminal.
An agent can then skip its own warning sound, because the watcher sounds exactly when 1Password really prompts.

A dialog that appears plays Antic from the EncoreInfinitum alert tones.
One still open after 60 s plays the more intense Text-Message-Acknowledgement-Exclamation and is notified once more, and then isn't alerted again.
`--first-sound` and `--second-sound` replace them.

## Run it

From a checkout of this repository, on macOS:

```bash
nix run .#onepassword-dialog-watcher -- --dry-run
```

`--dry-run` makes no sound and sends no notification, and prints one line for every change to a 1Password window.
`--once` takes a single sample and exits 0 when a dialog is up, 1 when none is.
`--help` describes the detection rule, the output and the exit codes.

## How it tells a dialog

It reads the window list twice a second, with no Screen Recording permission.
An approval dialog is a window that 1Password owns, that is on screen, above layer 0, and not Quick Access.
Quick Access is told by its title when titles are readable, otherwise by its 550-point width.

## Layout

- `Sources/OnePasswordDialogWatcherCore/`: the matching rule, the alert state machine, the dry-run lines and the option parser, all pure, and the alert commands and the stop on SIGINT and SIGTERM, with the commands' paths passed in.
- `Sources/onepassword-dialog-watcher/`: the window list, the real `afplay` and `terminal-notifier`, and the poll loop.
- `Tests/onepassword-dialog-watcher-tests/`: the core's tests, a plain executable, because nixpkgs' swiftpm has no XCTest runner on macOS; the alert commands are stub scripts.
- `package.nix`: the Nix build, which runs the tests and puts `terminal-notifier` on the program's `PATH`.
