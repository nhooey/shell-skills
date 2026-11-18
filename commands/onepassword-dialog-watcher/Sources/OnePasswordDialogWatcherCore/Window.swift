/// One entry of the window server's window list, reduced to what the rule and
/// the dry run need. `title` is nil when the window list leaves the name out,
/// as it does without Screen Recording permission.
public struct WindowRecord: Equatable {
    public var id: Int
    public var pid: Int
    public var owner: String
    public var layer: Int
    public var onScreen: Bool
    public var width: Double
    public var height: Double
    public var title: String?

    public init(
        id: Int, pid: Int, owner: String, layer: Int, onScreen: Bool,
        width: Double, height: Double, title: String?
    ) {
        self.id = id
        self.pid = pid
        self.owner = owner
        self.layer = layer
        self.onScreen = onScreen
        self.width = width
        self.height = height
        self.title = title
    }
}

public let onePasswordOwner = "1Password"
let quickAccessTitlePrefix = "Quick Access"
let quickAccessWidth = 550.0

public func onePasswordWindows(_ windows: [WindowRecord]) -> [WindowRecord] {
    windows.filter { $0.owner == onePasswordOwner }
}

/// Whether the window is a 1Password approval dialog: owned by 1Password, on
/// screen, above the normal window layer, and not Quick Access.
// Compromise: plan node onepassword-dialog-watcher
public func isApprovalDialog(_ window: WindowRecord) -> Bool {
    window.owner == onePasswordOwner && window.onScreen && window.layer > 0
        && !isQuickAccess(window)
}

/// Quick Access is told by its title when the title is readable, and
/// otherwise by its width.
// Compromise: plan node onepassword-dialog-watcher
func isQuickAccess(_ window: WindowRecord) -> Bool {
    if let title = window.title, !title.isEmpty {
        return title.hasPrefix(quickAccessTitlePrefix)
    }
    return abs(window.width - quickAccessWidth) < 0.5
}
