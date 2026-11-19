import Foundation

public enum NotificationReason: Equatable {
    case appeared
    case stillOpen
}

/// Each alert's sound: the first when a dialog appears, the second, more
/// intense, when it is still open after `stillOpenAfter`.
public enum AlertEffect: Equatable {
    case playSound(NotificationReason)
    case notify(NotificationReason)
    case removeNotification
}

/// Carries out an alert: plays the sound, sends or removes the notification.
public protocol AlertEffects: AnyObject {
    func perform(_ effect: AlertEffect)
}

/// How long a dialog stays open before it is notified a second time.
public let stillOpenAfter: TimeInterval = 60

/// Decides the alerts from successive samples of the approval dialogs on
/// screen, by window id:
/// - a dialog id not in the previous sample plays the first sound and
///   notifies, once per sample however many appeared;
/// - a dialog open for `stillOpenAfter` plays the second sound and notifies
///   once more, once per dialog, and is not alerted again;
/// - no dialog left removes the notification, as does `stop()`.
/// A dry run decides the same alerts and performs none of them.
public final class Alerter {
    private let effects: AlertEffects
    private let dryRun: Bool
    private let clock: () -> Date
    private var openSince: [Int: Date] = [:]
    private var renotified: Set<Int> = []
    private var notificationShown = false

    public init(effects: AlertEffects, dryRun: Bool, clock: @escaping () -> Date) {
        self.effects = effects
        self.dryRun = dryRun
        self.clock = clock
    }

    @discardableResult
    public func observe(dialogs: Set<Int>) -> [AlertEffect] {
        let now = clock()
        let appeared = dialogs.subtracting(openSince.keys)
        openSince = openSince.filter { dialogs.contains($0.key) }
        renotified.formIntersection(dialogs)
        for id in appeared { openSince[id] = now }

        let overdue = Set(
            openSince.filter { id, since in
                now.timeIntervalSince(since) >= stillOpenAfter && !renotified.contains(id)
            }.keys)
        renotified.formUnion(overdue)

        var decided: [AlertEffect] = []
        if !appeared.isEmpty {
            decided += [.playSound(.appeared), .notify(.appeared)]
        } else if !overdue.isEmpty {
            decided += [.playSound(.stillOpen), .notify(.stillOpen)]
        }
        if dialogs.isEmpty && notificationShown {
            decided.append(.removeNotification)
        }
        return apply(decided)
    }

    @discardableResult
    public func stop() -> [AlertEffect] {
        openSince = [:]
        renotified = []
        return apply(notificationShown ? [.removeNotification] : [])
    }

    private func apply(_ decided: [AlertEffect]) -> [AlertEffect] {
        for effect in decided {
            switch effect {
            case .notify: notificationShown = true
            case .removeNotification: notificationShown = false
            case .playSound: break
            }
            if !dryRun { effects.perform(effect) }
        }
        return decided
    }
}

public func describe(_ effect: AlertEffect, dryRun: Bool) -> String {
    let text: String
    switch effect {
    case .playSound(.appeared): text = "alert sound first (dialog appeared)"
    case .playSound(.stillOpen): text = "alert sound second (dialog still open after 60 s)"
    case .notify(.appeared): text = "alert notify (dialog appeared)"
    case .notify(.stillOpen): text = "alert notify (dialog still open after 60 s)"
    case .removeNotification: text = "alert remove notification"
    }
    return dryRun ? text + " (dry run: skipped)" : text
}
