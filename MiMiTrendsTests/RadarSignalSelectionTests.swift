import XCTest
@testable import MiMiTrends

final class RadarSignalSelectionTests: XCTestCase {
    func testKeepsNewestEventForEachSymbol() {
        let signals = [
            event("AAPL", source: "Sustained rise", at: 60),
            event("MSFT", source: "Rapid crash", at: 120),
            event("AAPL", source: "Rapid rise", at: 180)
        ]

        let selected = RadarSignalSelection.latestPerSymbol(signals, limit: 2)

        XCTAssertEqual(selected.map(\.symbol), ["AAPL", "MSFT"])
        XCTAssertEqual(selected.first?.signalSource, "Rapid rise")
    }

    private func event(_ symbol: String, source: String, at epoch: Int64) -> ScanResult {
        ScanResult(
            symbol: symbol, price: 100, anomalyScore: 0,
            priceAnomaly: nil, volumeAnomaly: nil, rangeAnomaly: nil,
            relativeVolume: nil, candleBodyRatio: 0,
            windowChangePercent: 1, windowVolume: 0, sessionVolume: 0,
            sessionTurnover: 0, signalAgeMinutes: 0, signalSource: source,
            updatedAtMillis: epoch, signalEpochMillis: epoch
        )
    }
}
