import Foundation
import AVFoundation
import CoreGraphics
import CoreMedia
import ImageIO

// MARK: - Supporting Enums

/// Where a string or number is inserted relative to the filename stem.
enum InsertPosition: Hashable, Codable {
    /// Prepend to the beginning of the name.
    case prefix
    /// Append to the end of the name.
    case suffix
    /// Insert at a 0-based character index. Negative values count from the end.
    /// The index is clamped to the valid range [0, name.count].
    case atIndex(Int)
}

/// How to transform the case of a filename stem.
enum CaseStyle: String, Hashable, Codable, CaseIterable {
    case lowercase
    case uppercase
    case titleCase
    case camelCase
    case snakeCase
    case kebabCase
}

/// Which characters to remove from the filename stem.
enum CharacterSetPreset: Hashable, Codable {
    /// All Unicode whitespace characters.
    case whitespace
    /// Everything that is not alphanumeric, dot, dash, or underscore.
    case specialChars
    /// ASCII digit characters 0–9.
    case digits
    /// A literal set of characters supplied by the user.
    case custom(String)
}

/// The source of a date used when inserting a date token into a filename.
enum DateSource: String, Hashable, Codable {
    case creationDate
    case modificationDate
    case currentDate
}

/// EXIF and media metadata fields that can be inserted into a filename.
enum MetadataTag: String, Hashable, Codable, CaseIterable {
    case exifDate
    case exifCamera
    case exifLens
    case exifISO
    case imageWidth
    case imageHeight
    case audioArtist
    case audioAlbum
    case audioTrackNumber
    case audioYear
    case videoResolution
    case videoDuration
}

/// Which end of the string to trim when truncating.
enum TruncateSide: String, Hashable, Codable {
    case start
    case end
}

// MARK: - Context

/// Read-only context injected by `RenameEngine` when applying rules to a specific file.
/// Keeps `RenameRule.apply` pure (no side effects, deterministic for the same context).
struct RenameContext {
    /// The `FileItem` being renamed — used for date metadata and EXIF extraction.
    let item: FileItem
    /// The reference date for `.currentDate` source. Injected so tests can control it.
    let referenceDate: Date

    init(item: FileItem, referenceDate: Date = .now) {
        self.item = item
        self.referenceDate = referenceDate
    }
}

// MARK: - RenameRule

/// A single, composable rename transformation.
///
/// Rules are pure functions: `apply(to:index:total:context:)` transforms a filename stem
/// and returns the result without any side effects or filesystem access (except for metadata
/// reads inside `insertMetadata`, which are performed synchronously on `RenameActor`).
enum RenameRule: Identifiable, Hashable, Codable {

    // MARK: Text Manipulation

    /// Replace all occurrences of a literal string or regex pattern.
    case replace(find: String, replacement: String, isCaseSensitive: Bool, isRegex: Bool)

    /// Insert a string at a given position within the stem.
    case insert(text: String, position: InsertPosition)

    /// Remove a character range by index. Negative indices count from the end.
    case removeRange(from: Int, to: Int)

    /// Remove all characters that match the given preset from the stem.
    case removeCharacters(preset: CharacterSetPreset)

    // MARK: Case

    /// Transform the entire stem to a different case style.
    case changeCase(style: CaseStyle)

    // MARK: Numbering

    /// Append or prepend a sequential number to each file in the batch.
    case addNumber(position: InsertPosition, startAt: Int, step: Int, padToDigits: Int, separator: String)

    /// Replace the entire filename with a base name and sequential number.
    /// Example: baseName="Week", separator=" ", startAt=1, step=1 → "Week 1", "Week 2", …
    /// - baseName: The fixed text portion (e.g., "Week", "Screenshot", "Photo")
    /// - startAt: The first number in the sequence (default 1)
    /// - step: Increment between numbers (default 1)
    /// - padToDigits: Zero-pad the number to this many digits (0 = no padding)
    /// - separator: String placed between the base name and the number (e.g., " ", "_", "-")
    case sequentialName(baseName: String, startAt: Int, step: Int, padToDigits: Int, separator: String)

    // MARK: Date & Time

    /// Insert a formatted date string derived from the file's metadata.
    case insertDate(source: DateSource, format: String, position: InsertPosition, separator: String)

    // MARK: Metadata

    /// Insert EXIF or media metadata tags. Silently skipped for unsupported file types.
    case insertMetadata(tags: [MetadataTag], separator: String, position: InsertPosition)

    // MARK: Extension

    /// Change the file extension. An empty string removes the extension entirely.
    /// This rule operates on the extension string, not the stem.
    case changeExtension(newExtension: String)

    // MARK: Truncation

    /// Trim the stem to at most `maxLength` characters, removing from `from`.
    case truncate(maxLength: Int, from: TruncateSide)

    // MARK: - Identifiable

    // DECISION: RenameRule uses a case-name string id because the enum carries no UUID.
    // The view model wraps each rule in ActiveRule (which has a UUID) for stable list identity.
    var id: String {
        switch self {
        case .replace:          return "replace"
        case .insert:           return "insert"
        case .removeRange:      return "removeRange"
        case .removeCharacters: return "removeCharacters"
        case .changeCase:       return "changeCase"
        case .addNumber:        return "addNumber"
        case .sequentialName:   return "sequentialName"
        case .insertDate:       return "insertDate"
        case .insertMetadata:   return "insertMetadata"
        case .changeExtension:  return "changeExtension"
        case .truncate:         return "truncate"
        }
    }

    // MARK: - Human-readable label

    /// Display name shown in the rule builder.
    var displayName: String {
        switch self {
        case .replace:          return "Replace Text"
        case .insert:           return "Insert Text"
        case .removeRange:      return "Remove Range"
        case .removeCharacters: return "Remove Characters"
        case .changeCase:       return "Change Case"
        case .addNumber:        return "Add Number"
        case .sequentialName:   return "Sequential Name"
        case .insertDate:       return "Insert Date"
        case .insertMetadata:   return "Insert Metadata"
        case .changeExtension:  return "Change Extension"
        case .truncate:         return "Truncate"
        }
    }

    // MARK: - Apply

    /// Apply this rule to a filename **stem** (without extension) and return the transformed stem.
    ///
    /// - Parameters:
    ///   - name:    The filename stem (no extension, no path).
    ///   - index:   0-based position of this file within the batch (used for sequential numbering).
    ///   - total:   Total number of files in the batch.
    ///   - context: File-specific metadata context (item + reference date).
    /// - Returns: The transformed stem, or the original stem if the rule cannot be applied.
    func apply(to name: String, index: Int, total: Int, context: RenameContext) -> String {
        switch self {

        // MARK: replace
        case let .replace(find, replacement, isCaseSensitive, isRegex):
            guard !find.isEmpty else { return name }
            if isRegex {
                let options: NSRegularExpression.Options = isCaseSensitive ? [] : .caseInsensitive
                guard let regex = try? NSRegularExpression(pattern: find, options: options) else {
                    return name   // invalid pattern — engine will mark result as invalidRegex
                }
                let range = NSRange(name.startIndex..., in: name)
                return regex.stringByReplacingMatches(in: name, range: range, withTemplate: replacement)
            } else {
                let options: String.CompareOptions = isCaseSensitive
                    ? .literal
                    : [.caseInsensitive, .diacriticInsensitive]
                return name.replacingOccurrences(of: find, with: replacement, options: options)
            }

        // MARK: insert
        case let .insert(text, position):
            return insertString(text, into: name, at: position)

        // MARK: removeRange
        case let .removeRange(from, to):
            let len = name.count
            guard len > 0 else { return name }
            let start = resolveIndex(from, length: len)
            let end   = resolveIndex(to,   length: len)
            guard start <= end, start < len, end >= 0 else { return name }
            let clampedStart = max(0, start)
            let clampedEnd   = min(len - 1, end)
            guard clampedStart <= clampedEnd else { return name }
            var chars = Array(name)
            chars.removeSubrange(clampedStart...clampedEnd)
            return String(chars)

        // MARK: removeCharacters
        case let .removeCharacters(preset):
            let toRemove: CharacterSet
            switch preset {
            case .whitespace:
                toRemove = .whitespaces
            case .specialChars:
                // Keep alphanumerics, dot, dash, underscore — remove everything else
                toRemove = CharacterSet.alphanumerics
                    .union(CharacterSet(charactersIn: ".-_"))
                    .inverted
            case .digits:
                toRemove = .decimalDigits
            case .custom(let chars):
                toRemove = CharacterSet(charactersIn: chars)
            }
            return name.unicodeScalars
                .filter { !toRemove.contains($0) }
                .reduce("") { $0 + String($1) }

        // MARK: changeCase
        case let .changeCase(style):
            return applyCase(style, to: name)

        // MARK: addNumber
        case let .addNumber(position, startAt, step, padToDigits, separator):
            let number = startAt + index * step
            let numStr: String
            if padToDigits > 0 {
                numStr = String(format: "%0\(padToDigits)d", number)
            } else {
                numStr = "\(number)"
            }
            switch position {
            case .prefix:
                return numStr + separator + name
            case .suffix:
                return name + separator + numStr
            case .atIndex(let idx):
                let token = numStr + separator
                return insertString(token, into: name, at: .atIndex(idx))
            }

        // MARK: sequentialName
        case let .sequentialName(baseName, startAt, step, padToDigits, separator):
            let number = startAt + index * step
            let numStr: String
            if padToDigits > 0 {
                numStr = String(format: "%0\(padToDigits)d", number)
            } else {
                numStr = "\(number)"
            }
            // Replace the entire stem with baseName + separator + number
            return baseName + separator + numStr

        // MARK: insertDate
        case let .insertDate(source, format, position, separator):
            let date: Date?
            switch source {
            case .creationDate:     date = context.item.creationDate
            case .modificationDate: date = context.item.modificationDate
            case .currentDate:      date = context.referenceDate
            }
            guard let date else { return name }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            let dateStr = formatter.string(from: date)
            return insertString(dateStr + separator, into: name, at: position)

        // MARK: insertMetadata
        case let .insertMetadata(tags, separator, position):
            let values = tags.compactMap { readMetadataTag($0, for: context.item) }
            guard !values.isEmpty else { return name }
            let token = values.joined(separator: separator)
            return insertString(token, into: name, at: position)

        // MARK: changeExtension
        case .changeExtension:
            // Extension is handled by the engine — this case is a no-op on the stem.
            return name

        // MARK: truncate
        case let .truncate(maxLength, from):
            guard maxLength >= 0, name.count > maxLength else { return name }
            let excess = name.count - maxLength
            switch from {
            case .end:
                return String(name.dropLast(excess))
            case .start:
                return String(name.dropFirst(excess))
            }
        }
    }

    // MARK: - Helpers

    private func insertString(_ text: String, into name: String, at position: InsertPosition) -> String {
        switch position {
        case .prefix:
            return text + name
        case .suffix:
            return name + text
        case .atIndex(let raw):
            let len = name.count
            let idx = resolveIndex(raw, length: len)
            let clamped = max(0, min(len, idx))
            var chars = Array(name)
            chars.insert(contentsOf: text, at: clamped)
            return String(chars)
        }
    }

    /// Converts a possibly-negative index to a non-negative index.
    /// Negative values count from the end: -1 → last character index.
    private func resolveIndex(_ raw: Int, length: Int) -> Int {
        raw < 0 ? max(0, length + raw) : raw
    }

    private func applyCase(_ style: CaseStyle, to name: String) -> String {
        switch style {
        case .lowercase:
            return name.lowercased()
        case .uppercase:
            return name.uppercased()
        case .titleCase:
            return titleCaseFallback(name.lowercased())
        case .camelCase:
            let words = splitWords(name)
            guard !words.isEmpty else { return name }
            let lower = words.map { $0.lowercased() }
            let first = lower[0]
            let rest  = lower.dropFirst().map { $0.capitalized }
            return ([first] + rest).joined()
        case .snakeCase:
            return splitWords(name, separators: CharacterSet(charactersIn: " -"))
                .map { $0.lowercased() }
                .joined(separator: "_")
        case .kebabCase:
            return splitWords(name, separators: CharacterSet(charactersIn: " _"))
                .map { $0.lowercased() }
                .joined(separator: "-")
        }
    }

    private func titleCaseFallback(_ name: String) -> String {
        let delimiters: Set<Character> = [" ", "_", "-"]
        var result = Array(name)
        var capitalizeNext = true
        for i in result.indices {
            if delimiters.contains(result[i]) {
                capitalizeNext = true
            } else if capitalizeNext {
                result[i] = Character(result[i].uppercased())
                capitalizeNext = false
            }
        }
        return String(result)
    }

    /// Split a name on the given separator character set (default: spaces, underscores, hyphens).
    private func splitWords(_ name: String, separators: CharacterSet = CharacterSet(charactersIn: " _-")) -> [String] {
        name.components(separatedBy: separators).filter { !$0.isEmpty }
    }

    // MARK: - Metadata Reading

    /// Read a single metadata tag from the file synchronously.
    /// Returns `nil` if the tag is not available for this file type.
    private func readMetadataTag(_ tag: MetadataTag, for item: FileItem) -> String? {
        switch tag {
        case .exifDate, .exifCamera, .exifLens, .exifISO, .imageWidth, .imageHeight:
            return readImageMetadata(tag, url: item.url)
        case .audioArtist, .audioAlbum, .audioTrackNumber, .audioYear,
             .videoResolution, .videoDuration:
            return readAVMetadata(tag, url: item.url)
        }
    }

    private func readImageMetadata(_ tag: MetadataTag, url: URL) -> String? {
        // TODO(future): support more EXIF tags (GPS, exposure, etc.)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }

        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let pixel = props

        switch tag {
        case .exifDate:
            return exif?[kCGImagePropertyExifDateTimeOriginal] as? String
        case .exifCamera:
            return tiff?[kCGImagePropertyTIFFMake] as? String
        case .exifLens:
            return exif?[kCGImagePropertyExifLensModel] as? String
        case .exifISO:
            if let iso = (exif?[kCGImagePropertyExifISOSpeedRatings] as? [Any])?.first {
                return "\(iso)"
            }
            return nil
        case .imageWidth:
            if let w = pixel[kCGImagePropertyPixelWidth] as? Int { return "\(w)" }
            return nil
        case .imageHeight:
            if let h = pixel[kCGImagePropertyPixelHeight] as? Int { return "\(h)" }
            return nil
        default:
            return nil
        }
    }

    private func readAVMetadata(_ tag: MetadataTag, url: URL) -> String? {
        // TODO(future): Consider async AVAsset API once available in a non-async context.
        // DECISION: Using synchronous AVURLAsset metadata loading here because this
        // function runs on RenameActor (background), not MainActor. The synchronous
        // AVMetadataItem.value(forKey:) path is used for simplicity; if it becomes
        // unavailable in future SDKs, switch to async AVAsset.load(.metadata).
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])

        switch tag {
        case .videoResolution:
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                return "\(Int(abs(size.width)))x\(Int(abs(size.height)))"
            }
            return nil
        case .videoDuration:
            let d = asset.duration
            guard d.isValid && !d.isIndefinite else { return nil }
            let secs = Int(CMTimeGetSeconds(d))
            return String(format: "%d:%02d", secs / 60, secs % 60)
        case .audioArtist:
            return commonMetadataValue(asset: asset, identifier: .commonIdentifierArtist)
        case .audioAlbum:
            return commonMetadataValue(asset: asset, identifier: .commonIdentifierAlbumName)
        case .audioTrackNumber:
            return commonMetadataValue(asset: asset, identifier: .iTunesMetadataTrackNumber)
        case .audioYear:
            if let raw = commonMetadataValue(asset: asset, identifier: .commonIdentifierCreationDate) {
                return String(raw.prefix(4))
            }
            return nil
        default:
            return nil
        }
    }

    private func commonMetadataValue(asset: AVURLAsset, identifier: AVMetadataIdentifier) -> String? {
        let items = AVMetadataItem.metadataItems(from: asset.commonMetadata, filteredByIdentifier: identifier)
        return items.first?.stringValue
    }
}

