import Foundation

public let notificationGroup = "1password-approval"
let notificationTitle = "1Password"
let notificationMessage = "Approval needed"

/// The programs the alerts run.
public struct AlertCommands {
    /// Plays the sound file it is given.
    public var player: String
    /// The first alert's sound file, when a dialog appears.
    public var firstSound: String
    /// The second alert's, when the dialog is still open after `stillOpenAfter`.
    public var secondSound: String
    /// terminal-notifier, or nil to notify with `osascript` alone.
    public var notifier: String?
    public var osascript: String

    public init(
        player: String, firstSound: String, secondSound: String, notifier: String?,
        osascript: String
    ) {
        self.player = player
        self.firstSound = firstSound
        self.secondSound = secondSound
        self.notifier = notifier
        self.osascript = osascript
    }

    public static func system(firstSound: String, secondSound: String, path: String)
        -> AlertCommands
    {
        AlertCommands(
            player: "/usr/bin/afplay", firstSound: firstSound, secondSound: secondSound,
            notifier: executable(named: "terminal-notifier", onPath: path),
            osascript: "/usr/bin/osascript")
    }
}

public func executable(named name: String, onPath path: String) -> String? {
    path.split(separator: ":")
        .map { "\($0)/\(name)" }
        .first { FileManager.default.isExecutableFile(atPath: $0) }
}

/// Runs the alerts as child processes, without blocking the poll loop.
///
/// A child is forgotten on the thread that sees it exit, so a wait on the
/// main queue, as in a signal handler, still sees it go. A child with an
/// exit action is forgotten after that action runs on the main queue, so a
/// fallback it starts is waited for too.
public final class ProcessEffects: AlertEffects {
    private let commands: AlertCommands
    private let reportError: (String) -> Void
    private let lock = NSLock()
    private var running: [Process] = []
    private var sounds: [Process] = []

    public init(commands: AlertCommands, reportError: @escaping (String) -> Void) {
        self.commands = commands
        self.reportError = reportError
    }

    public func perform(_ effect: AlertEffect) {
        switch effect {
        case .playSound(.appeared):
            launch(commands.player, [commands.firstSound], isSound: true)
        case .playSound(.stillOpen):
            launch(commands.player, [commands.secondSound], isSound: true)
        case .notify:
            guard let notifier = commands.notifier else {
                notifyWithOsascript()
                return
            }
            launch(
                notifier,
                [
                    "-title", notificationTitle, "-message", notificationMessage,
                    "-group", notificationGroup,
                ]
            ) { status in
                if status != 0 { self.notifyWithOsascript() }
            }
        case .removeNotification:
            if let notifier = commands.notifier {
                launch(notifier, ["-remove", notificationGroup])
            }
        }
    }

    /// Stops any sound still playing.
    public func stopSounds() {
        for sound in locked({ sounds }) where sound.isRunning { sound.terminate() }
    }

    /// Waits for every child, and any fallback they start, to finish, or
    /// until the deadline. Returns whether they all finished.
    @discardableResult
    public func waitForAll(until deadline: Date = .distantFuture) -> Bool {
        while !locked({ running.isEmpty }) {
            if Date() >= deadline { return false }
            _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        return true
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private func forget(_ process: Process) {
        locked {
            running.removeAll { $0 === process }
            sounds.removeAll { $0 === process }
        }
    }

    private func notifyWithOsascript() {
        launch(
            commands.osascript,
            [
                "-e",
                "display notification \"\(notificationMessage)\" with title \"\(notificationTitle)\"",
            ])
    }

    private func launch(
        _ path: String, _ arguments: [String], isSound: Bool = false,
        onExit: ((Int32) -> Void)? = nil
    ) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.terminationHandler = { finished in
            guard let onExit else {
                self.forget(finished)
                return
            }
            DispatchQueue.main.async {
                onExit(finished.terminationStatus)
                self.forget(finished)
            }
        }
        do {
            // Registered before it runs, so its exit can't be seen first.
            locked {
                running.append(process)
                if isSound { sounds.append(process) }
            }
            try process.run()
        } catch {
            forget(process)
            reportError("cannot run \(path): \(error.localizedDescription)")
            onExit?(-1)
        }
    }
}
