public enum WindowEvent: Equatable {
    case appeared(WindowRecord)
    case changed(from: WindowRecord, to: WindowRecord)
    case gone(WindowRecord)
}

/// The changes between two samples of the window list, by window id, in id
/// order: windows that appeared or changed, then windows that went.
public func windowEvents(from previous: [WindowRecord], to current: [WindowRecord]) -> [WindowEvent]
{
    let before = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    let after = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    let appearedOrChanged: [WindowEvent] = after.keys.sorted().compactMap { id in
        let window = after[id]!
        guard let old = before[id] else { return .appeared(window) }
        return old == window ? nil : .changed(from: old, to: window)
    }
    let gone: [WindowEvent] = before.keys.sorted().filter { after[$0] == nil }.map {
        .gone(before[$0]!)
    }
    return appearedOrChanged + gone
}

/// One line per event: the window's signature and whether the dialog rule
/// matched it, and for a change, the old values of the fields that changed.
public func describe(_ event: WindowEvent) -> String {
    switch event {
    case .appeared(let window):
        return "window appeared " + signature(window)
    case .gone(let window):
        return "window gone     " + signature(window)
    case .changed(let old, let new):
        let was = fields(old).enumerated()
            .filter { index, field in field != fields(new)[index] }
            .map { $0.element }
        let suffix = was.isEmpty ? "" : " (was \(was.joined(separator: " ")))"
        return "window changed  " + signature(new) + suffix
    }
}

private func signature(_ window: WindowRecord) -> String {
    (["id=\(window.id)"] + fields(window) + ["dialog=\(yesNo(isApprovalDialog(window)))"])
        .joined(separator: " ")
}

private func fields(_ window: WindowRecord) -> [String] {
    [
        "pid=\(window.pid)",
        "layer=\(window.layer)",
        "size=\(points(window.width))x\(points(window.height))",
        "on-screen=\(yesNo(window.onScreen))",
        "title=\(quoted(window.title))",
    ]
}

private func yesNo(_ value: Bool) -> String { value ? "yes" : "no" }

private func points(_ value: Double) -> String {
    value == value.rounded() ? String(Int(value)) : String(value)
}

/// A readable title in double quotes, `-` when the title is unreadable.
private func quoted(_ title: String?) -> String {
    guard let title else { return "-" }
    let escaped = title.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}
