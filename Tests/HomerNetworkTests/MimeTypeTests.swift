import Testing
@testable import HomerNetwork

@Suite("MimeType")
struct MimeTypeTests {

    // MARK: - Known extensions

    @Test("known extensions resolve to correct MIME type", arguments: [
        ("pdf",  "application/pdf"),
        ("doc",  "application/msword"),
        ("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        ("png",  "image/png"),
        ("jpg",  "image/jpeg"),
        ("jpeg", "image/jpeg"),
        ("gif",  "image/gif"),
        ("mp4",  "video/mp4"),
        ("mp3",  "audio/mpeg"),
        ("json", "application/json"),
        ("txt",  "text/plain"),
        ("html", "text/html"),
    ])
    func knownExtensionMapsCorrectly(ext: String, expected: String) {
        let sut = MimeType(extension: ext)
        #expect(sut.rawValue == expected)
    }

    // MARK: - Case-insensitivity

    @Test("extension lookup is case-insensitive", arguments: [
        "PDF", "PNG", "JPG", "JPEG", "Mp4", "JSON"
    ])
    func extensionIsCaseInsensitive(ext: String) {
        let lower = MimeType(extension: ext.lowercased())
        let upper = MimeType(extension: ext)
        #expect(lower == upper)
    }

    // MARK: - jpg and jpeg both map to image/jpeg

    @Test("jpg and jpeg both resolve to image/jpeg")
    func jpgAndJpegAreSame() {
        let jpg  = MimeType(extension: "jpg")
        let jpeg = MimeType(extension: "jpeg")
        #expect(jpg == jpeg)
        #expect(jpg.rawValue == "image/jpeg")
    }

    // MARK: - Unknown extension falls back to octet-stream

    @Test("unknown extension resolves to application/octet-stream", arguments: [
        "xyz", "bin", "unknown", "", "swift", "mov"
    ])
    func unknownExtensionFallsBack(ext: String) {
        let sut = MimeType(extension: ext)
        #expect(sut == .octetStream)
        #expect(sut.rawValue == "application/octet-stream")
    }

    // MARK: - Static accessors

    @Test("static accessors match expected raw values")
    func staticAccessors() {
        #expect(MimeType.pdf.rawValue       == "application/pdf")
        #expect(MimeType.png.rawValue       == "image/png")
        #expect(MimeType.jpeg.rawValue      == "image/jpeg")
        #expect(MimeType.gif.rawValue       == "image/gif")
        #expect(MimeType.mp4.rawValue       == "video/mp4")
        #expect(MimeType.mp3.rawValue       == "audio/mpeg")
        #expect(MimeType.json.rawValue      == "application/json")
        #expect(MimeType.plainText.rawValue == "text/plain")
        #expect(MimeType.html.rawValue      == "text/html")
        #expect(MimeType.octetStream.rawValue == "application/octet-stream")
    }

    // MARK: - RawRepresentable round-trip

    @Test("rawValue round-trip preserves the string")
    func rawValueRoundTrip() {
        let custom = MimeType(rawValue: "application/vnd.custom+json")
        #expect(custom.rawValue == "application/vnd.custom+json")
    }

    // MARK: - Hashable / Equatable

    @Test("two MimeTypes with same rawValue are equal")
    func equality() {
        let a = MimeType(rawValue: "image/png")
        let b = MimeType(rawValue: "image/png")
        #expect(a == b)
    }

    @Test("two MimeTypes with different rawValues are not equal")
    func inequality() {
        #expect(MimeType.png != MimeType.jpeg)
    }
}
