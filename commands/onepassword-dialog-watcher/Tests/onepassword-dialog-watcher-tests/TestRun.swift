// A minimal test harness: nixpkgs' swiftpm can't run XCTest on macOS, so the
// tests are a plain executable that prints one line per test and exits 1 on
// any failure.

final class TestRun {
    private(set) var failed: [String] = []
    private var currentFailures: [String] = []

    func test(_ name: String, _ body: () throws -> Void) {
        currentFailures = []
        do {
            try body()
        } catch {
            currentFailures.append("threw \(error)")
        }
        if currentFailures.isEmpty {
            print("ok - \(name)")
        } else {
            print("not ok - \(name)")
            for failure in currentFailures { print("    \(failure)") }
            failed.append(name)
        }
    }

    func expect(_ condition: Bool, file: StaticString = #fileID, line: UInt = #line) {
        if !condition { currentFailures.append("\(file):\(line): expectation failed") }
    }

    func expectEqual<T: Equatable>(
        _ actual: T, _ expected: T, file: StaticString = #fileID, line: UInt = #line
    ) {
        if actual != expected {
            currentFailures.append(
                "\(file):\(line): got \(String(reflecting: actual)),"
                    + " expected \(String(reflecting: expected))")
        }
    }

    func expectThrows<E: Error & Equatable>(
        _ expected: E, file: StaticString = #fileID, line: UInt = #line, _ body: () throws -> Void
    ) {
        do {
            try body()
            currentFailures.append("\(file):\(line): expected \(expected) to be thrown")
        } catch let error as E {
            expectEqual(error, expected, file: file, line: line)
        } catch {
            currentFailures.append("\(file):\(line): threw \(error), expected \(expected)")
        }
    }
}
