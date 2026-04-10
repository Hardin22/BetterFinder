import Foundation

// MARK: - RenameError

/// Errors that can occur during the rename pipeline.
enum RenameError: LocalizedError {

    /// A regex pattern provided in a `replace` rule is syntactically invalid.
    case invalidRegexPattern(String)

    /// The destination filename already exists on disk at the time of the write.
    case destinationAlreadyExists(URL)

    /// An underlying `FileManager` error occurred during the disk rename.
    case fileSystemError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidRegexPattern(let pattern):
            return "Invalid regex pattern: \"\(pattern)\""
        case .destinationAlreadyExists(let url):
            return "A file named \"\(url.lastPathComponent)\" already exists."
        case .fileSystemError(let err):
            return err.localizedDescription
        }
    }
}

// MARK: - ConflictSummary

/// A summary of a naming conflict detected during preview.
struct ConflictSummary: Identifiable {
    let id: UUID = UUID()
    /// The proposed name that would be shared by more than one file.
    let proposedName: String
    /// How many files would receive this name.
    let count: Int
}
