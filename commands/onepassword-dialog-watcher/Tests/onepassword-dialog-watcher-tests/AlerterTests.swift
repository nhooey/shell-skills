import Foundation
import OnePasswordDialogWatcherCore

private final class RecordingEffects: AlertEffects {
    var performed: [AlertEffect] = []
    func perform(_ effect: AlertEffect) { performed.append(effect) }
}

private final class ManualClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    func advance(_ seconds: TimeInterval) { now += seconds }
}

private func makeAlerter(dryRun: Bool = false) -> (Alerter, RecordingEffects, ManualClock) {
    let effects = RecordingEffects()
    let clock = ManualClock()
    return (Alerter(effects: effects, dryRun: dryRun, clock: { clock.now }), effects, clock)
}

func alerterTests(_ t: TestRun) {
    t.test("appear plays the sound and notifies once") {
        let (alerter, effects, clock) = makeAlerter()
        alerter.observe(dialogs: [7])
        alerter.observe(dialogs: [7])
        clock.advance(1)
        alerter.observe(dialogs: [7])
        t.expectEqual(effects.performed, [.playSound(.appeared), .notify(.appeared)])
    }

    t.test("60 s later plays the second sound, notifies once more, and never again") {
        let (alerter, effects, clock) = makeAlerter()
        alerter.observe(dialogs: [7])
        clock.advance(59)
        alerter.observe(dialogs: [7])
        t.expectEqual(effects.performed, [.playSound(.appeared), .notify(.appeared)])
        clock.advance(1)
        alerter.observe(dialogs: [7])
        clock.advance(60)
        alerter.observe(dialogs: [7])
        clock.advance(600)
        alerter.observe(dialogs: [7])
        t.expectEqual(
            effects.performed,
            [.playSound(.appeared), .notify(.appeared), .playSound(.stillOpen), .notify(.stillOpen)])
    }

    t.test("close removes the notification") {
        let (alerter, effects, clock) = makeAlerter()
        alerter.observe(dialogs: [7])
        clock.advance(2)
        alerter.observe(dialogs: [])
        alerter.observe(dialogs: [])
        t.expectEqual(effects.performed, [.playSound(.appeared), .notify(.appeared), .removeNotification])
    }

    t.test("the notification stays while another dialog remains") {
        let (alerter, effects, _) = makeAlerter()
        alerter.observe(dialogs: [7])
        alerter.observe(dialogs: [7, 8])
        alerter.observe(dialogs: [8])
        t.expectEqual(
            effects.performed,
            [.playSound(.appeared), .notify(.appeared), .playSound(.appeared), .notify(.appeared)])
        alerter.observe(dialogs: [])
        t.expectEqual(effects.performed.last, .removeNotification)
    }

    t.test("two dialogs appearing in one sample alert once") {
        let (alerter, effects, _) = makeAlerter()
        alerter.observe(dialogs: [7, 8])
        t.expectEqual(effects.performed, [.playSound(.appeared), .notify(.appeared)])
    }

    t.test("a dialog replaced within one sample alerts again") {
        let (alerter, effects, _) = makeAlerter()
        alerter.observe(dialogs: [7])
        alerter.observe(dialogs: [9])
        t.expectEqual(
            effects.performed,
            [.playSound(.appeared), .notify(.appeared), .playSound(.appeared), .notify(.appeared)])
    }

    t.test("stop removes a shown notification") {
        let (alerter, effects, _) = makeAlerter()
        alerter.observe(dialogs: [7])
        alerter.stop()
        t.expectEqual(effects.performed.last, .removeNotification)
    }

    t.test("stop with nothing shown does nothing") {
        let (alerter, effects, _) = makeAlerter()
        alerter.observe(dialogs: [])
        alerter.stop()
        t.expectEqual(effects.performed, [])
    }

    t.test("a dry run produces no effects") {
        let (alerter, effects, clock) = makeAlerter(dryRun: true)
        let decided = alerter.observe(dialogs: [7])
        clock.advance(61)
        alerter.observe(dialogs: [7])
        alerter.observe(dialogs: [])
        alerter.stop()
        t.expectEqual(decided, [.playSound(.appeared), .notify(.appeared)])
        t.expectEqual(effects.performed, [])
    }

    t.test("a dry run's alert line says it was skipped") {
        t.expectEqual(
            describe(.playSound(.appeared), dryRun: false), "alert sound first (dialog appeared)")
        t.expectEqual(
            describe(.playSound(.stillOpen), dryRun: false),
            "alert sound second (dialog still open after 60 s)")
        t.expectEqual(
            describe(.removeNotification, dryRun: true),
            "alert remove notification (dry run: skipped)")
    }
}
