import XCTest
@testable import TheWatcher

/// Verifies the hierarchical rate fallback (§2.2). These are pure-logic tests
/// with no Core Data dependency.
final class RateResolverTests: XCTestCase {

    func testEntryOverrideWinsOverEverything() {
        let result = RateResolver.resolve(
            entryOverride: 500,
            matterRate: 400,
            clientRate: 300,
            feeEarnerBaseRate: 250
        )
        XCTAssertEqual(result.rate, 500)
        XCTAssertEqual(result.source, .entryOverride)
    }

    func testMatterRateUsedWhenNoEntryOverride() {
        let result = RateResolver.resolve(
            entryOverride: nil,
            matterRate: 400,
            clientRate: 300,
            feeEarnerBaseRate: 250
        )
        XCTAssertEqual(result.rate, 400)
        XCTAssertEqual(result.source, .matter)
    }

    func testClientRateUsedWhenNoEntryOrMatterRate() {
        let result = RateResolver.resolve(
            entryOverride: nil,
            matterRate: nil,
            clientRate: 300,
            feeEarnerBaseRate: 250
        )
        XCTAssertEqual(result.rate, 300)
        XCTAssertEqual(result.source, .client)
    }

    func testFeeEarnerDefaultUsedAsFinalFallback() {
        let result = RateResolver.resolve(
            entryOverride: nil,
            matterRate: nil,
            clientRate: nil,
            feeEarnerBaseRate: 250
        )
        XCTAssertEqual(result.rate, 250)
        XCTAssertEqual(result.source, .feeEarnerDefault)
    }

    func testZeroOverrideIsRespectedAndNotTreatedAsAbsent() {
        // A deliberately configured rate of 0 (e.g. pro bono) must win over the
        // lower levels rather than falling through.
        let result = RateResolver.resolve(
            entryOverride: nil,
            matterRate: 0,
            clientRate: 300,
            feeEarnerBaseRate: 250
        )
        XCTAssertEqual(result.rate, 0)
        XCTAssertEqual(result.source, .matter)
    }
}
