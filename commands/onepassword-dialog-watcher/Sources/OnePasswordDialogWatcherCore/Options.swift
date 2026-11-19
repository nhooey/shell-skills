let alertTones = "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones"
public let defaultFirstSound = alertTones + "/EncoreInfinitum/Antic-EncoreInfinitum.caf"
public let defaultSecondSound = alertTones + "/Text-Message-Acknowledgement-Exclamation.caf"

public struct Options: Equatable {
    public var dryRun: Bool
    public var once: Bool
    public var help: Bool
    public var firstSound: String
    public var secondSound: String

    public init(
        dryRun: Bool, once: Bool, help: Bool, firstSound: String = defaultFirstSound,
        secondSound: String = defaultSecondSound
    ) {
        self.dryRun = dryRun
        self.once = once
        self.help = help
        self.firstSound = firstSound
        self.secondSound = secondSound
    }
}

public struct UsageError: Error, Equatable {
    public var message: String
    public init(message: String) { self.message = message }
}

public func parseOptions(_ arguments: [String]) throws -> Options {
    var options = Options(dryRun: false, once: false, help: false)
    var remaining = arguments[...]
    func value(of option: String) throws -> String {
        guard let value = remaining.popFirst(), !value.isEmpty else {
            throw UsageError(message: "\(option) needs a sound file")
        }
        return value
    }
    while let argument = remaining.popFirst() {
        switch argument {
        case "--dry-run": options.dryRun = true
        case "--once": options.once = true
        case "--help": options.help = true
        case "--first-sound": options.firstSound = try value(of: argument)
        case "--second-sound": options.secondSound = try value(of: argument)
        default: throw UsageError(message: "unknown argument: \(argument)")
        }
    }
    return options
}

public let helpText = """
    Usage: onepassword-dialog-watcher [--dry-run] [--once]
                                      [--first-sound FILE] [--second-sound FILE]
           onepassword-dialog-watcher --help

    Play a sound and send a notification while a 1Password approval dialog is
    on screen, for every client that asks 1Password: SSH signing, op,
    SecretSpec, a terminal.

    Twice a second it reads the window list. A window is an approval dialog
    when 1Password owns it, it is on screen, its layer is above 0, and it isn't
    Quick Access: a title starting "Quick Access" when titles are readable,
    else a width of 550 points. It needs no Screen Recording permission and
    asks for none.

    When a dialog appears it plays the first sound (/usr/bin/afplay) and sends
    the notification "Approval needed" titled "1Password" (terminal-notifier,
    group 1password-approval, or osascript when terminal-notifier is missing or
    fails). A dialog still open after 60 s plays the second, more intense sound
    and is notified once more, and is not alerted again. When no dialog
    remains, the notification is removed. SIGINT and SIGTERM stop it within a
    second, stop any sound playing and remove the notification.

    Output, one timestamped line each on stdout:
      alert ...          an alert raised, or skipped in a dry run
      window appeared    a 1Password window appeared (dry run and --once)
      window changed     ... changed, with the old values in "(was ...)"
      window gone        ... went away
    A window line shows id, pid, layer, size in points, on-screen yes|no,
    title ("-" when unreadable) and dialog yes|no, whether the rule matched.

    Options:
      --dry-run  Make no sound and send no notification; print every change to
                 any 1Password window and the alerts that would be raised.
      --once     Take one sample, print 1Password's windows and the alerts,
                 alert unless --dry-run, and exit 0 when a dialog is up, 1
                 when none is.
      --first-sound FILE
                 The sound when a dialog appears, default
                 \(defaultFirstSound)
      --second-sound FILE
                 The sound when it is still open after 60 s, default
                 \(defaultSecondSound)
      --help     Show this help and exit.

    Exit status:
      0  stopped by SIGINT or SIGTERM; with --once, a dialog is on screen
      1  with --once, no dialog is on screen
      2  bad usage

    Examples:
      onepassword-dialog-watcher --dry-run
      onepassword-dialog-watcher --once --dry-run
      onepassword-dialog-watcher
    """
