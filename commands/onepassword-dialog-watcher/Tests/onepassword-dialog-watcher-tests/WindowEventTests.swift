import OnePasswordDialogWatcherCore

private let precursor = WindowRecord(
    id: 5, pid: 100, owner: "1Password", layer: 101, onScreen: false,
    width: 400, height: 100, title: nil)

private var shown: WindowRecord {
    var window = precursor
    window.onScreen = true
    window.height = 325
    return window
}

func windowEventTests(_ t: TestRun) {
    t.test("the first sample reports every window as appeared") {
        t.expectEqual(windowEvents(from: [], to: [precursor]), [.appeared(precursor)])
    }
    t.test("a change is reported with both states") {
        t.expectEqual(
            windowEvents(from: [precursor], to: [shown]), [.changed(from: precursor, to: shown)])
    }
    t.test("an unchanged window isn't reported") {
        t.expectEqual(windowEvents(from: [shown], to: [shown]), [])
    }
    t.test("a gone window is reported") {
        t.expectEqual(windowEvents(from: [shown], to: []), [.gone(shown)])
    }
    t.test("the appeared line shows the signature and the rule") {
        t.expectEqual(
            describe(.appeared(shown)),
            "window appeared id=5 pid=100 layer=101 size=400x325 on-screen=yes title=- dialog=yes")
    }
    t.test("the changed line names what changed") {
        t.expectEqual(
            describe(.changed(from: precursor, to: shown)),
            "window changed  id=5 pid=100 layer=101 size=400x325 on-screen=yes title=- dialog=yes"
                + " (was size=400x100 on-screen=no)")
    }
    t.test("a readable title is quoted") {
        var quickAccess = shown
        quickAccess.width = 550
        quickAccess.height = 108
        quickAccess.title = "Quick Access — 1Password"
        t.expectEqual(
            describe(.gone(quickAccess)),
            "window gone     id=5 pid=100 layer=101 size=550x108 on-screen=yes"
                + " title=\"Quick Access — 1Password\" dialog=no")
    }
}
