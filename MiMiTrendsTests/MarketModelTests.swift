import XCTest
@testable import MiMiTrends

final class MarketModelTests: XCTestCase {
    func testVolumeStatusAggregationMatchesDesktopRules() {
        XCTAssertEqual(VolumeStatus.aggregate([]), .missing)
        XCTAssertEqual(VolumeStatus.aggregate([.reported, .reported]), .reported)
        XCTAssertEqual(VolumeStatus.aggregate([.zero, .zero]), .zero)
        XCTAssertEqual(VolumeStatus.aggregate([.zero, .missing]), .missing)
        XCTAssertEqual(VolumeStatus.aggregate([.reported, .missing]), .estimated)
        XCTAssertEqual(VolumeStatus.aggregate([.estimated, .zero]), .estimated)
        XCTAssertTrue(VolumeStatus.reported.isReliable)
        XCTAssertFalse(VolumeStatus.zero.isReliable)
    }

    func testMinuteBarValidationMatchesDesktopRules() {
        let valid = MinuteBar(
            symbol: "ENR.DE", minuteEpochSeconds: 60,
            open: 151, high: 152, low: 150, close: 151.5,
            volume: 0, volumeStatus: .missing
        )
        XCTAssertTrue(valid.isValid)
        XCTAssertFalse(MinuteBar(
            symbol: "ENR.DE", minuteEpochSeconds: 61,
            open: 151, high: 152, low: 150, close: 151.5,
            volume: 10
        ).isValid)
        XCTAssertFalse(MinuteBar(
            symbol: "ENR.DE", minuteEpochSeconds: 60,
            open: 151, high: 152, low: 150, close: 151.5,
            volume: 0
        ).isValid)
        XCTAssertFalse(MinuteBar(
            symbol: "ENR.DE", minuteEpochSeconds: 60,
            open: 151, high: 150, low: 149, close: 151.5,
            volume: 10
        ).isValid)
    }

    func testQuoteAndInstrumentRetainProviderIdentityAndOptionalFields() throws {
        let instrument = ProviderInstrument(
            provider: "EURONEXT", symbol: "TEST", identifier: "ISIN-TEST",
            mic: "XPAR", currency: "EUR", resolvedName: "Test Company",
            updatedAtMillis: 1_700_000_000_000
        )
        let quote = ProviderQuoteSnapshot(
            provider: instrument.provider, symbol: instrument.symbol,
            identifier: instrument.identifier, currency: instrument.currency,
            last: 42.5, bid: nil, ask: nil, bidSize: nil, askSize: nil,
            sessionVolume: nil, sessionTurnover: nil, averagePrice: nil,
            executions: nil, sessionHigh: nil, sessionLow: nil,
            previousClose: nil, observedAtMillis: 1_700_000_001_000
        )
        XCTAssertEqual(try JSONDecoder().decode(ProviderInstrument.self, from: JSONEncoder().encode(instrument)), instrument)
        XCTAssertEqual(try JSONDecoder().decode(ProviderQuoteSnapshot.self, from: JSONEncoder().encode(quote)), quote)
        XCTAssertNil(quote.bid)
    }

    func testSignalCoreMatchesDesktopTestFixtureWithoutNaNSentinels() throws {
        let signal = ScanResult(
            symbol: "TEST", price: 100, anomalyScore: 4,
            priceAnomaly: 5, volumeAnomaly: nil, rangeAnomaly: 5,
            relativeVolume: nil, candleBodyRatio: 0.8,
            windowChangePercent: 4, windowVolume: 0,
            sessionVolume: 1_000, sessionTurnover: 10_000_000,
            signalAgeMinutes: 0, signalSource: "Impulse ↑", updatedAtMillis: 0
        )
        XCTAssertEqual(signal.dataStatus, "CACHE")
        XCTAssertEqual(signal.signalWindowLabel, "1m")
        XCTAssertEqual(signal.signalPrice, signal.price)
        XCTAssertEqual(signal.signalEpochMillis, signal.updatedAtMillis)
        XCTAssertNil(signal.bidPrice)
        XCTAssertNil(signal.askPrice)
        XCTAssertNil(signal.entryQualityScore)
        XCTAssertEqual(signal.entryQualityLabel, "Unavailable")
        XCTAssertEqual(signal.analysisUpdatedAtMillis, signal.updatedAtMillis)
        XCTAssertEqual(signal.scanEvaluatedAtMillis, signal.updatedAtMillis)
        XCTAssertFalse(signal.isRetained)
        XCTAssertEqual(try JSONDecoder().decode(ScanResult.self, from: JSONEncoder().encode(signal)), signal)
    }
}
