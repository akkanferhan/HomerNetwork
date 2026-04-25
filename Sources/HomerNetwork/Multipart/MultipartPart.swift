import Foundation

/// A single part in a multipart/form-data body.
///
/// Parts are either text fields (`name=value`) or binary file uploads
/// (`name=<bytes>` with a filename and content type). The text/file
/// distinction is encoded in ``Kind`` so callers cannot accidentally mix
/// the two.
public struct MultipartPart: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        case text(String)
        case file(data: Data, filename: String, mimeType: MimeType)
    }

    public let name: String
    public let kind: Kind

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }

    /// Convenience factory for a text field.
    public static func text(name: String, value: String) -> MultipartPart {
        MultipartPart(name: name, kind: .text(value))
    }

    /// Convenience factory for a file field. The ``MimeType`` defaults to
    /// the one inferred from `filename`'s extension.
    public static func file(
        name: String,
        data: Data,
        filename: String,
        mimeType: MimeType? = nil
    ) -> MultipartPart {
        let resolved = mimeType ?? MimeType(extension: (filename as NSString).pathExtension)
        return MultipartPart(name: name, kind: .file(data: data, filename: filename, mimeType: resolved))
    }
}
