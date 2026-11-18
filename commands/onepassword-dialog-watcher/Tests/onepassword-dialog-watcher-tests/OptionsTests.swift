import OnePasswordDialogWatcherCore

func optionsTests(_ t: TestRun) {
    t.test("no arguments watches") {
        t.expectEqual(try parseOptions([]), Options(dryRun: false, once: false, help: false))
    }
    t.test("every option is read") {
        t.expectEqual(
            try parseOptions(["--once", "--dry-run"]), Options(dryRun: true, once: true, help: false))
        t.expectEqual(try parseOptions(["--help"]).help, true)
        t.expectEqual(
            try parseOptions(["--first-sound", "/a.caf", "--second-sound", "/b.caf"]),
            Options(
                dryRun: false, once: false, help: false, firstSound: "/a.caf", secondSound: "/b.caf"
            ))
    }
    t.test("the sounds default to Antic, then Text-Message-Acknowledgement-Exclamation") {
        let options = try parseOptions([])
        t.expectEqual(
            options.firstSound,
            "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/EncoreInfinitum/Antic-EncoreInfinitum.caf"
        )
        t.expectEqual(
            options.secondSound,
            "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Text-Message-Acknowledgement-Exclamation.caf"
        )
    }
    t.test("a sound option without its file is a usage error") {
        t.expectThrows(UsageError(message: "--second-sound needs a sound file")) {
            _ = try parseOptions(["--second-sound"])
        }
    }
    t.test("an unknown argument is a usage error") {
        t.expectThrows(UsageError(message: "unknown argument: --loud")) {
            _ = try parseOptions(["--loud"])
        }
    }
}
