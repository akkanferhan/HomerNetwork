import Foundation

/// A `multipart/form-data` payload comprised of zero or more ``MultipartPart`` values.
public struct MultipartFormData: Sendable, Hashable {
    public let parts: [MultipartPart]
    public let boundary: String

    public init(parts: [MultipartPart], boundary: String = MultipartFormData.makeBoundary()) {
        self.parts = parts
        self.boundary = boundary
    }

    /// Generates a unique boundary token. The ``MultipartFormat/boundaryPrefix``
    /// keeps logs readable; the suffix is a UUID.
    public static func makeBoundary() -> String {
        "\(MultipartFormat.boundaryPrefix)\(UUID().uuidString)"
    }

    /// Encodes the parts into a single `Data` blob terminated by the
    /// closing boundary, ready to assign to `URLRequest.httpBody`.
    ///
    /// - Throws: ``NetworkEncodingError/multipartFailure(_:)`` if any
    ///   `name` or `filename` contains a CRLF or other character that
    ///   would corrupt the boundary, or if a string fragment cannot be
    ///   encoded as UTF-8.
    public func encode() throws -> Data {
        var body = Data()
        let lineBreak = MultipartFormat.lineBreak
        let boundaryLine = "\(MultipartFormat.boundaryDelimiter)\(boundary)"

        for part in parts {
            try body.appendUTF8("\(boundaryLine)\(lineBreak)")
            switch part.kind {
            case .text(let value):
                let safeName = try Self.escapeQuotedString(part.name, label: "name")
                try body.appendUTF8("\(MultipartFormat.contentDispositionField): \(MultipartFormat.formDataDisposition); name=\"\(safeName)\"\(lineBreak)\(lineBreak)")
                try body.appendUTF8("\(value)\(lineBreak)")
            case .file(let data, let filename, let mimeType):
                let safeName = try Self.escapeQuotedString(part.name, label: "name")
                let safeFilename = try Self.escapeQuotedString(filename, label: "filename")
                try body.appendUTF8("\(MultipartFormat.contentDispositionField): \(MultipartFormat.formDataDisposition); name=\"\(safeName)\"; filename=\"\(safeFilename)\"\(lineBreak)")
                try body.appendUTF8("\(MultipartFormat.contentTypeField): \(mimeType.rawValue)\(lineBreak)\(lineBreak)")
                body.append(data)
                try body.appendUTF8(lineBreak)
            }
        }
        try body.appendUTF8("\(boundaryLine)\(MultipartFormat.boundaryDelimiter)\(lineBreak)")
        return body
    }

    /// Escapes the value of a `Content-Disposition` quoted-string parameter
    /// (`name` or `filename`). Quotes are backslash-escaped per RFC 2616
    /// quoted-pair; CR/LF are rejected entirely because they would
    /// terminate the header and let the field contents bleed into the body.
    private static func escapeQuotedString(_ value: String, label: String) throws -> String {
        for scalar in value.unicodeScalars where scalar == "\r" || scalar == "\n" {
            throw NetworkEncodingError.multipartFailure(
                "\(label) cannot contain CR or LF characters"
            )
        }
        return value.replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// The full Content-Type header value, including the boundary token.
    public var contentTypeHeaderValue: String {
        "\(MultipartFormat.contentTypeTemplate)\(boundary)"
    }
}

extension Data {
    /// Appends `string` as UTF-8 bytes; throws if the string cannot be
    /// represented in UTF-8 so the caller surfaces a multipart encoding
    /// failure instead of producing a silently truncated body.
    mutating func appendUTF8(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw NetworkEncodingError.multipartFailure("non-UTF-8 fragment: \(string)")
        }
        append(data)
    }
}
