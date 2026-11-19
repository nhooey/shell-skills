import OnePasswordDialogWatcherCore

private func window(
    owner: String = "1Password",
    layer: Int = 101,
    onScreen: Bool = true,
    width: Double = 400,
    height: Double = 325,
    title: String? = "1Password"
) -> WindowRecord {
    WindowRecord(
        id: 1, pid: 100, owner: owner, layer: layer, onScreen: onScreen,
        width: width, height: height, title: title)
}

func windowRuleTests(_ t: TestRun) {
    t.test("the CLI approval dialog matches") {
        t.expect(isApprovalDialog(window()))
    }
    t.test("a dialog with no title still matches") {
        t.expect(isApprovalDialog(window(title: nil)))
    }
    t.test("Quick Access with a title doesn't match") {
        t.expect(
            !isApprovalDialog(window(width: 550, height: 108, title: "Quick Access — 1Password")))
    }
    t.test("Quick Access with a title at another width doesn't match") {
        t.expect(
            !isApprovalDialog(window(width: 600, height: 108, title: "Quick Access — 1Password")))
    }
    t.test("Quick Access with no title (550 wide) doesn't match") {
        t.expect(!isApprovalDialog(window(width: 550, height: 108, title: nil)))
    }
    t.test("a layer-0 window doesn't match") {
        t.expect(!isApprovalDialog(window(layer: 0, width: 1800, height: 39, title: nil)))
    }
    t.test("the dialog's off-screen 400x100 precursor doesn't match") {
        t.expect(!isApprovalDialog(window(onScreen: false, width: 400, height: 100)))
    }
    t.test("a window of another owner at layer 101 doesn't match") {
        t.expect(!isApprovalDialog(window(owner: "Finder")))
    }
    t.test("only 1Password's windows are kept") {
        let windows = [window(), window(owner: "Finder"), window(layer: 0)]
        t.expectEqual(onePasswordWindows(windows).count, 2)
    }
}
