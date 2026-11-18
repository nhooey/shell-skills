import Foundation
import OnePasswordDialogWatcherCore

/// Writes an executable shell script and returns its path.
private func stub(_ directory: URL, _ name: String, _ body: String) throws -> String {
    let path = directory.appendingPathComponent(name).path
    try "#!/bin/sh\n\(body)\n".write(toFile: path, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
    return path
}

/// Runs the main run loop, which drains the main queue, until `done` or the
/// deadline.
private func runMainLoop(until deadline: Date, _ done: () -> Bool) {
    while !done() && Date() < deadline {
        _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
}

private func lines(_ path: String) -> [String] {
    ((try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
        .split(separator: "\n").map(String.init)
}

func stopperTests(_ t: TestRun) {
    t.test("SIGINT with a dialog up stops within a second, silences the sound, removes the notification")
    {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("onepassword-dialog-watcher-tests-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let soundPID = directory.appendingPathComponent("sound.pid").path
        let notifierLog = directory.appendingPathComponent("notifier.log").path
        let commands = AlertCommands(
            player: try stub(directory, "afplay", "echo $$ > '\(soundPID)'\nexec /bin/sleep 30"),
            firstSound: "first.caf", secondSound: "second.caf",
            notifier: try stub(directory, "terminal-notifier", "echo \"$*\" >> '\(notifierLog)'"),
            osascript: "/usr/bin/true")
        let effects = ProcessEffects(commands: commands, reportError: { _ in })
        let alerter = Alerter(effects: effects, dryRun: false, clock: Date.init)
        var stoppedBy: String?
        let stopper = Stopper(alerter: alerter, effects: effects, dryRun: false, report: { _ in }) {
            stoppedBy = $0
        }
        stopper.handleSignals()
        defer { stopper.cancel() }

        alerter.observe(dialogs: [7])
        runMainLoop(until: Date(timeIntervalSinceNow: 5)) {
            FileManager.default.fileExists(atPath: soundPID) && lines(notifierLog).count == 1
        }
        let sound = pid_t(lines(soundPID).first ?? "") ?? 0
        t.expect(sound > 0 && kill(sound, 0) == 0)

        // A stop that never returns holds the main queue, so only another
        // thread can fail the test.
        let watchdog = DispatchWorkItem {
            print("not ok - SIGINT with a dialog up: still stopping after 5 s")
            kill(sound, SIGKILL)
            exit(1)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: watchdog)
        let sent = Date()
        kill(getpid(), SIGINT)
        runMainLoop(until: sent.addingTimeInterval(5)) { stoppedBy != nil }
        watchdog.cancel()

        t.expectEqual(stoppedBy, "SIGINT")
        t.expect(Date().timeIntervalSince(sent) < 1)
        t.expect(kill(sound, 0) != 0)
        t.expectEqual(lines(notifierLog).last, "-remove 1password-approval")
    }

    t.test("a dialog plays the first sound, the second after 60 s, and no more") {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("onepassword-dialog-watcher-tests-\(getpid())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let playerLog = directory.appendingPathComponent("player.log").path
        let notifierLog = directory.appendingPathComponent("notifier.log").path
        let commands = AlertCommands(
            player: try stub(directory, "afplay", "echo \"$*\" >> '\(playerLog)'"),
            firstSound: "first.caf", secondSound: "second.caf",
            notifier: try stub(directory, "terminal-notifier", "echo \"$1\" >> '\(notifierLog)'"),
            osascript: "/usr/bin/true")
        let effects = ProcessEffects(commands: commands, reportError: { _ in })
        var now = Date(timeIntervalSince1970: 1_000_000)
        let alerter = Alerter(effects: effects, dryRun: false, clock: { now })

        for seconds in [0.0, 30, 30, 60, 600] {
            now += seconds
            alerter.observe(dialogs: [7])
            t.expect(effects.waitForAll(until: Date(timeIntervalSinceNow: 5)))
        }

        t.expectEqual(lines(playerLog), ["first.caf", "second.caf"])
        t.expectEqual(lines(notifierLog), ["-title", "-title"])
    }
}
