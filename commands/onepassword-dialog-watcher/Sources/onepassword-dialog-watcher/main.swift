// onepassword-dialog-watcher: play a sound and send a notification while a
// 1Password approval dialog is on screen. `--help` describes the options.
//
// This file is the shell around OnePasswordDialogWatcherCore: it reads the
// window list, names the real alert commands, prints, and runs the poll loop.

import CoreGraphics
import Foundation
import OnePasswordDialogWatcherCore

let pollInterval: DispatchTimeInterval = .milliseconds(500)

// MARK: Window list

// Compromise: plan node onepassword-dialog-watcher
func sampleWindows() -> [WindowRecord] {
    guard
        let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID)
            as? [[String: Any]]
    else { return [] }
    return onePasswordWindows(list.compactMap(windowRecord))
}

func windowRecord(_ info: [String: Any]) -> WindowRecord? {
    guard
        let owner = info[kCGWindowOwnerName as String] as? String,
        let id = info[kCGWindowNumber as String] as? Int,
        let boundsInfo = info[kCGWindowBounds as String] as? NSDictionary,
        let bounds = CGRect(dictionaryRepresentation: boundsInfo as CFDictionary)
    else { return nil }
    return WindowRecord(
        id: id,
        pid: info[kCGWindowOwnerPID as String] as? Int ?? 0,
        owner: owner,
        layer: info[kCGWindowLayer as String] as? Int ?? 0,
        onScreen: info[kCGWindowIsOnscreen as String] as? Bool ?? false,
        width: Double(bounds.width),
        height: Double(bounds.height),
        title: info[kCGWindowName as String] as? String)
}

// MARK: Output

let timestampFormat: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()

func printLine(_ text: String) {
    print("\(timestampFormat.string(from: Date())) \(text)")
}

func printError(_ text: String) {
    FileHandle.standardError.write(Data("onepassword-dialog-watcher: \(text)\n".utf8))
}

// MARK: Main

setvbuf(stdout, nil, _IOLBF, 0)

let options: Options
do {
    options = try parseOptions(Array(CommandLine.arguments.dropFirst()))
} catch let error as UsageError {
    printError("\(error.message); see --help")
    exit(2)
} catch {
    printError("\(error); see --help")
    exit(2)
}
if options.help {
    print(helpText)
    exit(0)
}

for sound in [options.firstSound, options.secondSound]
where !FileManager.default.isReadableFile(atPath: sound) {
    printError("cannot read sound file \(sound); see --help")
    exit(2)
}

let effects = ProcessEffects(
    commands: .system(
        firstSound: options.firstSound, secondSound: options.secondSound,
        path: ProcessInfo.processInfo.environment["PATH"] ?? ""),
    reportError: printError)
let alerter = Alerter(effects: effects, dryRun: options.dryRun, clock: Date.init)

let stopper = Stopper(
    alerter: alerter, effects: effects, dryRun: options.dryRun, report: printLine
) { signalName in
    printLine("stopped by \(signalName)")
    exit(0)
}
stopper.handleSignals()

func dialogIDs(_ windows: [WindowRecord]) -> Set<Int> {
    Set(windows.filter(isApprovalDialog).map(\.id))
}

func alert(_ windows: [WindowRecord]) {
    for effect in alerter.observe(dialogs: dialogIDs(windows)) {
        printLine(describe(effect, dryRun: options.dryRun))
    }
}

if options.once {
    let windows = sampleWindows()
    for event in windowEvents(from: [], to: windows) { printLine(describe(event)) }
    alert(windows)
    effects.waitForAll()
    let dialogs = dialogIDs(windows).count
    printLine("dialogs on screen: \(dialogs)")
    exit(dialogs > 0 ? 0 : 1)
}

var previous: [WindowRecord] = []

func poll() {
    let windows = sampleWindows()
    if options.dryRun {
        for event in windowEvents(from: previous, to: windows) { printLine(describe(event)) }
    }
    previous = windows
    alert(windows)
}

// Compromise: plan node onepassword-dialog-watcher
let timer = DispatchSource.makeTimerSource(queue: .main)
timer.schedule(deadline: .now(), repeating: pollInterval, leeway: .milliseconds(50))
timer.setEventHandler(handler: poll)
timer.resume()

printError(
    "watching 1Password's windows every 0.5 s"
        + (options.dryRun ? " (dry run: no sound, no notification)" : ""))
dispatchMain()
