import Foundation

/// All user-configurable parameters for a search.
/// Default values reproduce the classic "name contains, current folder only" behaviour.
struct SearchOptions: Equatable {

    var matchMode: MatchMode      = .nameContains
    var scope:     SearchScope    = .currentFolder
    var fileKind:  FileKindFilter = .any

    init(matchMode: MatchMode = .nameContains,
         scope: SearchScope = .currentFolder,
         fileKind: FileKindFilter = .any) {
        self.matchMode = matchMode
        self.scope     = scope
        self.fileKind  = fileKind
    }

    // MARK: - Match Mode

    enum MatchMode: String, CaseIterable, Identifiable {
        case nameContains   = "Name Contains"
        case nameStartsWith = "Name Starts With"
        case nameEndsWith   = "Name Ends With"
        case nameExact      = "Exact Name"
        case extensionIs    = "Extension"

        var id: String { rawValue }

        var shortLabel: String {
            switch self {
            case .nameContains:   return "contains"
            case .nameStartsWith: return "starts with"
            case .nameEndsWith:   return "ends with"
            case .nameExact:      return "exact"
            case .extensionIs:    return "extension"
            }
        }

        var searchPlaceholder: String {
            self == .extensionIs ? "e.g. swift, png" : "Search"
        }
    }

    // MARK: - Scope

    enum SearchScope: String, CaseIterable, Identifiable {
        case currentFolder = "This Folder"
        case recursive     = "Subfolders"
        case homeDirectory = "Home"
        case entireDisk    = "Entire Disk"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .currentFolder:  return "folder"
            case .recursive:      return "folder.badge.questionmark"
            case .homeDirectory:  return "house"
            case .entireDisk:     return "internaldrive"
            }
        }

        /// True when results require an async search rather than client-side filtering.
        var isAsync: Bool { self != .currentFolder }
    }

    // MARK: - File Kind Filter

    enum FileKindFilter: String, CaseIterable, Identifiable {
        case any      = "Any Kind"
        case folder   = "Folder"
        case file     = "File"
        case image    = "Image"
        case video    = "Video"
        case audio    = "Audio"
        case document = "Document"
        case code     = "Code"
        case archive  = "Archive"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .any:      return "line.3.horizontal.decrease.circle"
            case .folder:   return "folder"
            case .file:     return "doc"
            case .image:    return "photo"
            case .video:    return "film"
            case .audio:    return "music.note"
            case .document: return "doc.text"
            case .code:     return "chevron.left.forwardslash.chevron.right"
            case .archive:  return "archivebox"
            }
        }

        /// File extensions for client-side kind filtering.
        var extensions: Set<String> {
            switch self {
            case .any, .folder, .file: return []
            case .image:
                return ["jpg","jpeg","png","gif","heic","heif","bmp","tiff","tif","webp","svg","ico","raw","cr2","cr3","nef","arw","dng"]
            case .video:
                return ["mp4","mov","avi","mkv","m4v","wmv","flv","webm","mpeg","mpg","3gp"]
            case .audio:
                return ["mp3","aac","flac","wav","aiff","m4a","ogg","wma","opus","caf"]
            case .document:
                return ["pdf","doc","docx","xls","xlsx","ppt","pptx","pages","numbers","key","txt","rtf","md","csv","odt","ods","odp"]
            case .code:
                return ["swift","py","js","ts","jsx","tsx","html","htm","css","scss","c","cpp","h","hpp","java","go","rs","rb","php","sh","zsh","bash","fish","json","yaml","yml","toml","xml","plist","kt","dart","vue","svelte","gradle"]
            case .archive:
                return ["zip","tar","gz","bz2","xz","7z","rar","dmg","pkg","deb","rpm","cab"]
            }
        }
    }
}
