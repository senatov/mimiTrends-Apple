import Foundation
import XCTest
@testable import MiMiTrends

final class FinnhubTradeDecoderTests: XCTestCase {
    func testDesktopTradeFixtureDecodes() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "finnhub-trades", withExtension: "json"))
        let trades = try FinnhubTradeDecoder.decode(Data(contentsOf: url))
        XCTAssertEqual(trades, [
            TradeTick(symbol: "AAPL", price: 189.5, timestampMillis: 1_710_000_000_000, volume: 4),
            TradeTick(symbol: "AAPL", price: 190.25, timestampMillis: 1_710_000_001_000, volume: 2)
        ])
    }

    func testDecoderSkipsUnusableTradesAndControlMessages() throws {
        let data = Data(#"{"type":"trade","data":[{"s":"","p":10},{"s":"AAPL"},{"s":"MSFT","p":20}]}"#.utf8)
        XCTAssertEqual(try FinnhubTradeDecoder.decode(data), [
            TradeTick(symbol: "MSFT", price: 20, timestampMillis: 0, volume: 0)
        ])
        XCTAssertTrue(try FinnhubTradeDecoder.decode(Data(#"{"type":"ping"}"#.utf8)).isEmpty)
    }

    func testDecoderReportsMalformedAndRejectedMessages() {
        XCTAssertThrowsError(try FinnhubTradeDecoder.decode(Data("bad json".utf8))) { error in
            guard case FinnhubStreamError.invalidMessage = error else { return XCTFail("Wrong error") }
        }
        XCTAssertThrowsError(try FinnhubTradeDecoder.decode(Data(#"{"type":"error","msg":"Invalid token"}"#.utf8))) { error in
            guard case FinnhubStreamError.providerRejected = error else { return XCTFail("Wrong error") }
        }
    }

    func testStreamURLRequiresAndEscapesToken() throws {
        XCTAssertThrowsError(try FinnhubTradeStream.streamURL(apiKey: " "))
        let url = try FinnhubTradeStream.streamURL(apiKey: "abc+def")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "wss")
        XCTAssertEqual(components.host, "ws.finnhub.io")
        XCTAssertEqual(components.queryItems?.first?.value, "abc+def")
    }

    func testSubscriptionMessagesAreBoundedAndOrdered() throws {
        let commands = try FinnhubTradeStream.subscriptionMessages(for: ["AAPL", "MSFT"])
        XCTAssertEqual(commands.count, 2)
        XCTAssertEqual(try JSONSerialization.jsonObject(with: Data(commands[0].utf8)) as? [String: String],
                       ["type": "subscribe", "symbol": "AAPL"])
        XCTAssertEqual(try JSONSerialization.jsonObject(with: Data(commands[1].utf8)) as? [String: String],
                       ["type": "subscribe", "symbol": "MSFT"])
        XCTAssertThrowsError(try FinnhubTradeStream.subscriptionMessages(for: []))
        XCTAssertThrowsError(try FinnhubTradeStream.subscriptionMessages(for: ["AAPL", "AAPL"]))
        XCTAssertThrowsError(try FinnhubTradeStream.subscriptionMessages(for: ["aapl"]))
        XCTAssertThrowsError(try FinnhubTradeStream.subscriptionMessages(
            for: ["A", "B", "C", "D", "E", "F"]
        ))
    }
}
