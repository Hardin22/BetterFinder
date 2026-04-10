import XCTest
@testable import BetterFinder

// MARK: - Helpers

private func makeItem(name: String, creationDate: Date? = nil, modDate: Date? = nil) -> FileItem {
    FileItem(
        id: UUID(),
        url: URL(fileURLWithPath: "/tmp/" + name),
        size: nil,
        isDirectory: false,
        isPackage: false,
        isHidden: false,
        isSymlink: false,
        modificationDate: modDate,
        creationDate: creationDate,
        contentType: nil
    )
}

private let engine = RenameEngine()

final class RenameEngineTests: XCTestCase {

    // MARK: Test 1 — replace literal string

    func testReplaceLiteralString() {
        let item = makeItem(name: "hello world.txt")
        let rules: [RenameRule] = [.replace(find: "world", replacement: "earth", isCaseSensitive: true, isRegex: false)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "hello earth.txt")
    }

    // MARK: Test 2 — replace with regex and capture group

    func testReplaceRegexCaptureGroup() {
        let item = makeItem(name: "photo_2024.jpg")
        // Capture group $1 wraps the year in brackets
        let rules: [RenameRule] = [.replace(find: "(\\d{4})", replacement: "[$1]", isCaseSensitive: false, isRegex: true)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "photo_[2024].jpg")
        XCTAssertFalse(results.first?.invalidRegex ?? true)
    }

    // MARK: Test 3 — replace with invalid regex

    func testReplaceInvalidRegexReturnsOriginal() {
        let item = makeItem(name: "document.pdf")
        let rules: [RenameRule] = [.replace(find: "[invalid(", replacement: "x", isCaseSensitive: false, isRegex: true)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "document.pdf",
                       "Invalid regex should leave filename unchanged")
        XCTAssertTrue(results.first?.invalidRegex ?? false,
                      "invalidRegex flag must be set for a bad pattern")
    }

    // MARK: Test 4 — changeCase snakeCase with spaces and hyphens

    func testChangeCaseSnakeCaseSpacesAndHyphens() {
        let item = makeItem(name: "Hello World-File.txt")
        let rules: [RenameRule] = [.changeCase(style: .snakeCase)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "hello_world_file.txt")
    }

    // MARK: Test 5 — changeCase camelCase with underscores

    func testChangeCaseCamelCaseUnderscores() {
        let item = makeItem(name: "my_cool_file.swift")
        let rules: [RenameRule] = [.changeCase(style: .camelCase)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "myCoolFile.swift")
    }

    // MARK: Test 6 — addNumber with zero-padding and suffix position

    func testAddNumberZeroPaddedSuffix() {
        let items = [
            makeItem(name: "photo.jpg"),
            makeItem(name: "image.jpg"),
            makeItem(name: "scan.jpg"),
        ]
        let rules: [RenameRule] = [.addNumber(position: .suffix, startAt: 1, step: 1, padToDigits: 3, separator: "_")]
        let results = engine.preview(rules: rules, items: items)
        XCTAssertEqual(results[0].proposed, "photo_001.jpg")
        XCTAssertEqual(results[1].proposed, "image_002.jpg")
        XCTAssertEqual(results[2].proposed, "scan_003.jpg")
    }

    // MARK: Test 7 — insertDate with currentDate (mocked to 2026-01-15)

    func testInsertDateCurrentDateMocked() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let mockDate = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let item = makeItem(name: "report.pdf")
        let rules: [RenameRule] = [.insertDate(source: .currentDate, format: "yyyy-MM-dd", position: .prefix, separator: "_")]
        let results = engine.preview(rules: rules, items: [item], referenceDate: mockDate)
        XCTAssertEqual(results.first?.proposed, "2026-01-15_report.pdf")
    }

    // MARK: Test 8 — removeRange with negative indices

    func testRemoveRangeNegativeIndices() {
        let item = makeItem(name: "filename_old.txt")
        // Remove last 4 characters of stem ("_old") → "filename"
        let rules: [RenameRule] = [.removeRange(from: -4, to: -1)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "filename.txt")
    }

    // MARK: Test 9 — rule chaining: replace → changeCase → addNumber

    func testRuleChaining() {
        let item = makeItem(name: "My File.txt")
        let rules: [RenameRule] = [
            .replace(find: " ", replacement: "_", isCaseSensitive: false, isRegex: false),
            .changeCase(style: .lowercase),
            .addNumber(position: .suffix, startAt: 1, step: 1, padToDigits: 2, separator: "-"),
        ]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "my_file-01.txt")
    }

    // MARK: Test 10 — conflict detection

    func testConflictDetectionTwoFilesProduceSameName() {
        let items = [
            makeItem(name: "alpha.jpg"),
            makeItem(name: "beta.jpg"),
        ]
        // Both stems become "file" → conflict
        let rules: [RenameRule] = [
            .replace(find: "alpha", replacement: "file", isCaseSensitive: false, isRegex: false),
            .replace(find: "beta",  replacement: "file", isCaseSensitive: false, isRegex: false),
        ]
        let results = engine.preview(rules: rules, items: items)
        XCTAssertTrue(results[0].conflict, "alpha.jpg should be flagged as conflicting")
        XCTAssertTrue(results[1].conflict, "beta.jpg should be flagged as conflicting")
    }

    // MARK: Test 11 — truncate from start and from end

    func testTruncateFromEnd() {
        let item = makeItem(name: "longfilename.txt")
        let rules: [RenameRule] = [.truncate(maxLength: 4, from: .end)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "long.txt")
    }

    func testTruncateFromStart() {
        let item = makeItem(name: "longfilename.txt")
        let rules: [RenameRule] = [.truncate(maxLength: 4, from: .start)]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "name.txt")
    }

    // MARK: Test 12 — changeExtension only changes extension, not stem

    func testChangeExtensionPreservesStem() {
        let item = makeItem(name: "document.txt")
        let rules: [RenameRule] = [.changeExtension(newExtension: "md")]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "document.md",
                       "Stem must be unchanged; only the extension should change")
    }

    func testChangeExtensionRemovesExtension() {
        let item = makeItem(name: "Makefile.txt")
        let rules: [RenameRule] = [.changeExtension(newExtension: "")]
        let results = engine.preview(rules: rules, items: [item])
        XCTAssertEqual(results.first?.proposed, "Makefile",
                       "Empty newExtension should remove the extension entirely")
    }
}
