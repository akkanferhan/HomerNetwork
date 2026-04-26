import Foundation

/// A MIME type used for multipart-form file fields.
///
/// `MimeType` is open-ended: well-known cases (`pdf`, `png`, …) come with
/// the canonical media type, while unrecognized extensions resolve to
/// `application/octet-stream` rather than asserting.
public struct MimeType: Sendable, Hashable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Resolves a media type from a file extension. Comparison is
    /// case-insensitive; unknown extensions yield `application/octet-stream`.
    public init(extension fileExtension: String) {
        switch fileExtension.lowercased() {
        case "pdf":          self = .pdf
        case "doc":          self = .doc
        case "docx":         self = .docx
        case "png":          self = .png
        case "jpg", "jpeg":  self = .jpeg
        case "gif":          self = .gif
        case "mp4":          self = .mp4
        case "mp3":          self = .mp3
        case "json":         self = .json
        case "txt":          self = .plainText
        case "html":         self = .html
        default:             self = .octetStream
        }
    }
}

public extension MimeType {
    static let pdf         = MimeType(rawValue: "application/pdf")
    static let doc         = MimeType(rawValue: "application/msword")
    static let docx        = MimeType(rawValue: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    static let png         = MimeType(rawValue: "image/png")
    static let jpeg        = MimeType(rawValue: "image/jpeg")
    static let gif         = MimeType(rawValue: "image/gif")
    static let mp4         = MimeType(rawValue: "video/mp4")
    static let mp3         = MimeType(rawValue: "audio/mpeg")
    static let json        = MimeType(rawValue: "application/json")
    static let plainText   = MimeType(rawValue: "text/plain")
    static let html        = MimeType(rawValue: "text/html")
    static let octetStream = MimeType(rawValue: "application/octet-stream")
}
