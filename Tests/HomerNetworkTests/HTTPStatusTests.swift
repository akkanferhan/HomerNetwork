import Testing
import Foundation
@testable import HomerNetwork

@Suite("HTTPStatus")
struct HTTPStatusTests {

    // MARK: - StatusCodeType range mapping

    @Test("informational maps 1xx codes", arguments: [100, 101, 102, 199])
    func informational(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .informational)
    }

    @Test("success maps 2xx codes", arguments: [200, 201, 204, 206, 299])
    func success(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .success)
    }

    @Test("redirection maps 3xx codes", arguments: [300, 301, 302, 304, 399])
    func redirection(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .redirection)
    }

    @Test("clientError maps 4xx codes", arguments: [400, 401, 403, 404, 422, 499])
    func clientError(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .clientError)
    }

    @Test("serverError maps 5xx codes", arguments: [500, 501, 502, 503, 599])
    func serverError(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .serverError)
    }

    @Test("unrecognized maps out-of-band codes", arguments: [0, 99, 600, 999, -1])
    func unrecognized(code: Int) {
        #expect(StatusCodeType(statusCode: code) == .unrecognized)
    }

    // MARK: - HTTPStatus.isSuccess

    @Test("isSuccess is true for 2xx codes", arguments: [200, 201, 204, 299])
    func isSuccessTrue(code: Int) {
        let sut = HTTPStatus(statusCode: code)
        #expect(sut.isSuccess == true)
    }

    @Test("isSuccess is false for non-2xx codes", arguments: [100, 301, 400, 404, 500])
    func isSuccessFalse(code: Int) {
        let sut = HTTPStatus(statusCode: code)
        #expect(sut.isSuccess == false)
    }

    // MARK: - HTTPStatus init

    @Test("init stores statusCode and statusType correctly")
    func initStoresValues() {
        let sut = HTTPStatus(statusCode: 404)
        #expect(sut.statusCode == 404)
        #expect(sut.statusType == .clientError)
    }

    @Test("init(httpURLResponse:) reads statusCode from response")
    func initFromHTTPURLResponse() throws {
        let url = try #require(URL(string: "https://example.com"))
        let response = try #require(
            HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)
        )
        let sut = HTTPStatus(httpURLResponse: response)
        #expect(sut.statusCode == 201)
        #expect(sut.statusType == .success)
        #expect(sut.isSuccess == true)
    }

    @Test("HTTPStatus is Hashable — equal codes produce same hash")
    func hashConsistency() {
        let a = HTTPStatus(statusCode: 200)
        let b = HTTPStatus(statusCode: 200)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("HTTPStatus with different codes are not equal")
    func inequality() {
        let a = HTTPStatus(statusCode: 200)
        let b = HTTPStatus(statusCode: 201)
        #expect(a != b)
    }
}
