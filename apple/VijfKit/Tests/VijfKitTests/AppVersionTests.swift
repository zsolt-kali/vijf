// SPEC.md → Backup screen: the version line
import Testing
@testable import VijfKit

@Suite struct AppVersionTests {
    @Test func showsTheCommitAndItsDate() {
        #expect(AppVersion.text(info: ["VijfCommit": "3116643", "VijfCommitDate": "2026-10-15"]) == "Version 3116643 · 15 Oct 2026")
        #expect(AppVersion.text(info: ["VijfCommit": "3116643+", "VijfCommitDate": "2026-10-05"]) == "Version 3116643+ · 5 Oct 2026")
    }

    @Test func withoutTheStampItSaysDev() {
        #expect(AppVersion.text(info: [:]) == "Version dev")
        #expect(AppVersion.text(info: nil) == "Version dev")
        #expect(AppVersion.text(info: ["VijfCommit": "3116643", "VijfCommitDate": ""]) == "Version 3116643")
    }
}
