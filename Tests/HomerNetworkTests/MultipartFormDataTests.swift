import Testing
import Foundation
@testable import HomerNetwork

@Suite("MultipartFormData")
struct MultipartFormDataTests {

    private static let fixedBoundary = "Boundary-TEST-1234"

    // MARK: - contentTypeHeaderValue

    @Test("contentTypeHeaderValue includes boundary token")
    func contentTypeHeaderValueIncludesBoundary() {
        let sut = MultipartFormData(parts: [], boundary: Self.fixedBoundary)
        #expect(sut.contentTypeHeaderValue == "multipart/form-data; boundary=\(Self.fixedBoundary)")
    }

    // MARK: - Empty payload

    @Test("encode with no parts produces only closing boundary")
    func encodeEmptyPartsHasClosingBoundary() {
        let sut = MultipartFormData(parts: [], boundary: Self.fixedBoundary)
        let data = sut.encode()
        let body = String(data: data, encoding: .utf8) ?? ""
        #expect(body == "--\(Self.fixedBoundary)--\r\n")
    }

    // MARK: - Text part formatting

    @Test("encode text part has correct Content-Disposition and value")
    func encodeTextPart() throws {
        let part = MultipartPart.text(name: "username", value: "homer")
        let sut = MultipartFormData(parts: [part], boundary: Self.fixedBoundary)
        let rawBody = sut.encode()
        let body = try #require(String(data: rawBody, encoding: .utf8))

        #expect(body.contains("--\(Self.fixedBoundary)\r\n"))
        #expect(body.contains("Content-Disposition: form-data; name=\"username\"\r\n\r\n"))
        #expect(body.contains("homer\r\n"))
        #expect(body.hasSuffix("--\(Self.fixedBoundary)--\r\n"))
    }

    // MARK: - File part formatting

    @Test("encode file part has Content-Disposition with filename and Content-Type")
    func encodeFilePart() throws {
        let fileData = Data("fake-image-bytes".utf8)
        let part = MultipartPart.file(
            name: "avatar",
            data: fileData,
            filename: "photo.png",
            mimeType: .png
        )
        let sut = MultipartFormData(parts: [part], boundary: Self.fixedBoundary)
        let rawBody = sut.encode()
        let body = try #require(String(data: rawBody, encoding: .utf8))

        #expect(body.contains("Content-Disposition: form-data; name=\"avatar\"; filename=\"photo.png\"\r\n"))
        #expect(body.contains("Content-Type: image/png\r\n\r\n"))
        #expect(body.hasSuffix("--\(Self.fixedBoundary)--\r\n"))
    }

    // MARK: - Multiple parts

    @Test("encode multiple parts appears in order with separate boundaries")
    func encodeMultipleParts() throws {
        let text = MultipartPart.text(name: "title", value: "hello")
        let file = MultipartPart.file(
            name: "doc",
            data: Data("pdf-bytes".utf8),
            filename: "readme.pdf",
            mimeType: .pdf
        )
        let sut = MultipartFormData(parts: [text, file], boundary: Self.fixedBoundary)
        let rawBody = sut.encode()
        let body = try #require(String(data: rawBody, encoding: .utf8))

        let components = body.components(separatedBy: "--\(Self.fixedBoundary)\r\n")
        // components[0] is empty prefix, [1] = text part, [2] = file part
        #expect(components.count >= 3)
        #expect(body.contains("name=\"title\""))
        #expect(body.contains("name=\"doc\""))
    }

    // MARK: - MimeType inferred from filename extension

    @Test("file part infers MIME type from filename when mimeType is nil")
    func fileMimeTypeInferredFromExtension() throws {
        let part = MultipartPart.file(
            name: "image",
            data: Data("bytes".utf8),
            filename: "shot.jpeg"
        )
        let sut = MultipartFormData(parts: [part], boundary: Self.fixedBoundary)
        let rawBody = sut.encode()
        let body = try #require(String(data: rawBody, encoding: .utf8))
        #expect(body.contains("Content-Type: image/jpeg"))
    }

    // MARK: - makeBoundary uniqueness

    @Test("makeBoundary produces unique values across calls")
    func boundaryUniqueness() {
        let a = MultipartFormData.makeBoundary()
        let b = MultipartFormData.makeBoundary()
        #expect(a != b)
        #expect(a.hasPrefix("Boundary-"))
    }

    // MARK: - Hashable

    @Test("two MultipartFormData with same parts and boundary are equal")
    func equality() {
        let a = MultipartFormData(
            parts: [.text(name: "k", value: "v")],
            boundary: "same-boundary"
        )
        let b = MultipartFormData(
            parts: [.text(name: "k", value: "v")],
            boundary: "same-boundary"
        )
        #expect(a == b)
    }
}
