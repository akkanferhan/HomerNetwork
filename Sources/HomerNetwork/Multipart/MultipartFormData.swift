import Foundation

/// A `multipart/form-data` payload comprised of zero or more ``MultipartPart`` values.
public struct MultipartFormData: Sendable, Hashable {
    public let parts: [MultipartPart]
    public let boundary: String

    public init(parts: [MultipartPart], boundary: String = MultipartFormData.makeBoundary()) {
        self.parts = parts
        self.boundary = boundary
    }

    /// Generates a unique boundary token. The `Boundary-` prefix is
    /// stable for log readability; the suffix is a UUID.
    public static func makeBoundary() -> String {
        "Boundary-\(UUID().uuidString)"
    }

    /// Encodes the parts into a single `Data` blob terminated by the
    /// closing boundary, ready to assign to `URLRequest.httpBody`.
    public func encode() -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for part in parts {
            body.append("--\(boundary)\(lineBreak)")
            switch part.kind {
            case .text(let value):
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"\(lineBreak)\(lineBreak)")
                body.append("\(value)\(lineBreak)")
            case .file(let data, let filename, let mimeType):
                body.append("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\(lineBreak)")
                body.append("Content-Type: \(mimeType.rawValue)\(lineBreak)\(lineBreak)")
                body.append(data)
                body.append(lineBreak)
            }
        }
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }

    /// The full Content-Type header value, including the boundary token.
    public var contentTypeHeaderValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
