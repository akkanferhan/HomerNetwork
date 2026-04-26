import Foundation

/// A MIME type used for multipart-form file fields.
///
/// `MimeType` is open-ended: well-known cases (`pdf`, `png`, …) come with
/// the canonical media type, while unrecognized extensions resolve to
/// `application/octet-stream` rather than asserting.
public struct MimeType: Sendable, Hashable, RawRepresentable {
    /// The IANA media type string (e.g. `image/png`).
    public let rawValue: String

    /// Wraps a raw media type string without validation.
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
    /// `application/pdf` — Portable Document Format.
    static let pdf         = MimeType(rawValue: "application/pdf")
    /// `application/msword` — legacy Microsoft Word document.
    static let doc         = MimeType(rawValue: "application/msword")
    /// `application/vnd.openxmlformats-officedocument.wordprocessingml.document` — Office Open XML Word document.
    static let docx        = MimeType(rawValue: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    /// `image/png` — PNG raster image.
    static let png         = MimeType(rawValue: "image/png")
    /// `image/jpeg` — JPEG raster image.
    static let jpeg        = MimeType(rawValue: "image/jpeg")
    /// `image/gif` — GIF raster image.
    static let gif         = MimeType(rawValue: "image/gif")
    /// `video/mp4` — MPEG-4 video container.
    static let mp4         = MimeType(rawValue: "video/mp4")
    /// `audio/mpeg` — MP3 audio.
    static let mp3         = MimeType(rawValue: "audio/mpeg")
    /// `application/json` — JSON document.
    static let json        = MimeType(rawValue: "application/json")
    /// `text/plain` — UTF-8 plain text.
    static let plainText   = MimeType(rawValue: "text/plain")
    /// `text/html` — HTML document.
    static let html        = MimeType(rawValue: "text/html")
    /// `application/octet-stream` — opaque binary fallback for unknown extensions.
    static let octetStream = MimeType(rawValue: "application/octet-stream")
}
