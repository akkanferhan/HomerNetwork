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
    public func encode() -> Data {
        var body = Data()
        let lineBreak = MultipartFormat.lineBreak
        let boundaryLine = "\(MultipartFormat.boundaryDelimiter)\(boundary)"

        for part in parts {
            body.append("\(boundaryLine)\(lineBreak)")
            switch part.kind {
            case .text(let value):
                body.append("\(MultipartFormat.contentDispositionField): \(MultipartFormat.formDataDisposition); name=\"\(part.name)\"\(lineBreak)\(lineBreak)")
                body.append("\(value)\(lineBreak)")
            case .file(let data, let filename, let mimeType):
                body.append("\(MultipartFormat.contentDispositionField): \(MultipartFormat.formDataDisposition); name=\"\(part.name)\"; filename=\"\(filename)\"\(lineBreak)")
                body.append("\(MultipartFormat.contentTypeField): \(mimeType.rawValue)\(lineBreak)\(lineBreak)")
                body.append(data)
                body.append(lineBreak)
            }
        }
        body.append("\(boundaryLine)\(MultipartFormat.boundaryDelimiter)\(lineBreak)")
        return body
    }

    /// The full Content-Type header value, including the boundary token.
    public var contentTypeHeaderValue: String {
        "\(MultipartFormat.contentTypeTemplate)\(boundary)"
    }
}

extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
