import Testing
import Foundation
@testable import HomerNetwork

@Suite("URLSanitizer")
struct URLSanitizerTests {

    @Test("redacts every query value when allowlist is empty")
    func redactsAllByDefault() {
        let sut = URLSanitizer()
        let result = sut.redact("https://api.example.com/v1?token=abc&page=1")
        #expect(result.contains("token=\(URLSanitizer.redactedToken)"))
        #expect(result.contains("page=\(URLSanitizer.redactedToken)"))
    }

    @Test("preserves values whose key is in the allowlist")
    func preservesAllowlistedKeys() {
        let sut = URLSanitizer(publicQueryKeys: ["page"])
        let result = sut.redact("https://api.example.com/v1?token=abc&page=1")
        #expect(result.contains("token=\(URLSanitizer.redactedToken)"))
        #expect(result.contains("page=1"))
    }

    @Test("comparison is case-insensitive")
    func caseInsensitiveAllowlist() {
        let sut = URLSanitizer(publicQueryKeys: ["Page"])
        let result = sut.redact("https://api.example.com/v1?PAGE=2")
        #expect(result.contains("PAGE=2"))
    }

    @Test("strips fragment from emitted URL")
    func stripsFragment() {
        let sut = URLSanitizer()
        let result = sut.redact("https://api.example.com/v1#section")
        #expect(!result.contains("#section"))
    }

    @Test("returns URLs without query unchanged")
    func passesThroughWithoutQuery() {
        let sut = URLSanitizer()
        let result = sut.redact("https://api.example.com/v1/items")
        #expect(result == "https://api.example.com/v1/items")
    }

}
