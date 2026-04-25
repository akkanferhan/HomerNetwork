import Testing
@testable import HomerNetwork

@Suite("HomerNetwork module")
struct HomerNetworkSmokeTests {
    @Test("module exposes a version string")
    func versionExists() {
        #expect(!HomerNetwork.version.isEmpty)
    }
}
