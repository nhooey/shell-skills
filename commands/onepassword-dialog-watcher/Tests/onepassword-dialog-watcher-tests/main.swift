import Foundation

let run = TestRun()
windowRuleTests(run)
alerterTests(run)
windowEventTests(run)
optionsTests(run)
stopperTests(run)

if run.failed.isEmpty {
    print("all tests passed")
} else {
    print("\(run.failed.count) failed: \(run.failed.joined(separator: ", "))")
    exit(1)
}
