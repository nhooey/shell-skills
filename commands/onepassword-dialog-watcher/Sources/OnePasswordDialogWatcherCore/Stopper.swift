import Foundation

/// How long a stop waits for the alert commands, such as the notification's
/// removal, before it finishes without them.
public let childrenGrace: TimeInterval = 0.5

/// Stops the watcher on SIGINT or SIGTERM: stops the sound, removes the
/// notification, reports the alerts, waits up to `childrenGrace` for the
/// alert commands, then calls `finish` with the signal's name. It runs on the
/// main queue, so nothing it waits for may need the main queue.
public final class Stopper {
    private let alerter: Alerter
    private let effects: ProcessEffects
    private let dryRun: Bool
    private let report: (String) -> Void
    private let finish: (String) -> Void
    private var sources: [DispatchSourceSignal] = []

    public init(
        alerter: Alerter, effects: ProcessEffects, dryRun: Bool,
        report: @escaping (String) -> Void, finish: @escaping (String) -> Void
    ) {
        self.alerter = alerter
        self.effects = effects
        self.dryRun = dryRun
        self.report = report
        self.finish = finish
    }

    /// Handles SIGINT and SIGTERM on the main queue from now on.
    public func handleSignals() {
        sources = [(SIGINT, "SIGINT"), (SIGTERM, "SIGTERM")].map { number, name in
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler { [weak self] in self?.stop(name) }
            source.resume()
            return source
        }
    }

    /// Restores the default handling of SIGINT and SIGTERM.
    public func cancel() {
        for source in sources { source.cancel() }
        sources = []
        signal(SIGINT, SIG_DFL)
        signal(SIGTERM, SIG_DFL)
    }

    func stop(_ signalName: String) {
        effects.stopSounds()
        for effect in alerter.stop() { report(describe(effect, dryRun: dryRun)) }
        if !effects.waitForAll(until: Date(timeIntervalSinceNow: childrenGrace)) {
            report("stopping with alert commands still running after \(childrenGrace) s")
        }
        finish(signalName)
    }
}
