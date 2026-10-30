import XCTest
@testable import MiMiTrends

final class RadarPaneLayoutTests: XCTestCase {
    func testWidePanelsStayReadableAtDefaultWindowSize() {
        let width = RadarPaneLayout.wideColumnWidth(totalWidth: 1024, ratio: 0.68)
        let height = RadarPaneLayout.wideTopHeight(totalHeight: 650, ratio: 0.72)

        XCTAssertGreaterThanOrEqual(width, 320)
        XCTAssertGreaterThanOrEqual(1024 - RadarPaneLayout.handleSize - width, 240)
        XCTAssertGreaterThanOrEqual(height, 400)
        XCTAssertGreaterThanOrEqual(650 - RadarPaneLayout.handleSize - height, 180)
    }

    func testDraggedAndRestoredRatiosAreClamped() {
        XCTAssertEqual(RadarPaneLayout.wideColumnWidth(totalWidth: 900, ratio: -1), 320)
        XCTAssertEqual(RadarPaneLayout.wideColumnWidth(totalWidth: 900, ratio: 2), 646)
        XCTAssertEqual(RadarPaneLayout.wideTopHeight(totalHeight: 500, ratio: .nan), 306)
    }

    func testStackedPanelsReserveChartAndSourceSpace() {
        let totalHeight: CGFloat = 600
        let signals = RadarPaneLayout.stackedSignalHeight(totalHeight: totalHeight, ratio: 1)
        let sources = RadarPaneLayout.stackedSourceHeight(
            totalHeight: totalHeight, signalHeight: signals, ratio: 1
        )

        XCTAssertGreaterThanOrEqual(signals, 140)
        XCTAssertGreaterThanOrEqual(sources, 120)
        XCTAssertGreaterThanOrEqual(
            totalHeight - 2 * RadarPaneLayout.handleSize - signals - sources, 260
        )
    }
}
