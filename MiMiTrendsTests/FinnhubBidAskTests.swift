import Foundation
import XCTest
@testable import MiMiTrends

final class FinnhubBidAskTests: XCTestCase {
    func testRequestKeepsCredentialOutOfURL() throws {
        let request = try FinnhubBidAskClient.request(symbol: " aapl ", apiKey: " fixture-key ")
        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "api.finnhub.io")
        XCTAssertEqual(components.path, "/api/v1/stock/bidask")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "symbol", value: "AAPL")])
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Finnhub-Token"), "fixture-key")
        XCTAssertFalse(components.url?.absoluteString.contains("fixture-key") ?? true)
        XCTAssertFalse(FinnhubBidAskClient.supports(symbol: "SAP.DE"))
        XCTAssertFalse(FinnhubBidAskClient.supports(symbol: "BINANCE:BTCUSDT"))
    }

    func testOfficialBidAskShapeDecodesIntoQuoteSnapshot() throws {
        let payload = Data(#"{"a":338.65,"av":2,"b":338.61,"bv":2,"t":1591995678874}"#.utf8)
        let quote = try FinnhubBidAskClient.decode(payload, symbol: "AAPL")

        XCTAssertEqual(quote.provider, "FINNHUB")
        XCTAssertEqual(quote.symbol, "AAPL")
        XCTAssertEqual(quote.currency, "USD")
        XCTAssertEqual(quote.bid, 338.61)
        XCTAssertEqual(quote.ask, 338.65)
        XCTAssertEqual(quote.bidSize, 2)
        XCTAssertEqual(quote.askSize, 2)
        XCTAssertEqual(quote.observedAtMillis, 1_591_995_678_874)
    }

    func testInvalidOrMissingExecutablePricesAreRejected() {
        for payload in [
            #"{"a":100,"b":101,"t":1591995678874}"#,
            #"{"a":100,"b":0,"t":1591995678874}"#,
            #"{"a":100,"b":99}"#
        ] {
            XCTAssertThrowsError(try FinnhubBidAskClient.decode(Data(payload.utf8), symbol: "AAPL"))
        }
    }

    func testSamplerLimitsRequestsAndKeepsOnlyFreshQuote() async {
        let probe = QuoteProbe()
        let sampler = FinnhubBidAskSampler { symbol, _ in
            await probe.load(symbol: symbol)
        }

        let first = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 100_000)
        let cached = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 120_000)
        let refreshed = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 160_000)
        let stale = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 290_000)

        XCTAssertNotNil(first)
        XCTAssertEqual(cached, first)
        XCTAssertEqual(refreshed, first)
        XCTAssertNil(stale)
        let requests = await probe.count
        XCTAssertEqual(requests, 3)
    }

    func testUnavailableAccessAndEuropeanSymbolDoNotKeepPolling() async {
        let probe = QuoteProbe(accessUnavailable: true)
        let sampler = FinnhubBidAskSampler { symbol, _ in
            try await probe.loadOrThrow(symbol: symbol)
        }

        let european = await sampler.latest(symbol: "SAP.DE", apiKey: "fixture", nowMillis: 100_000)
        let first = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 100_000)
        let later = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 220_000)

        XCTAssertNil(european)
        XCTAssertNil(first)
        XCTAssertNil(later)
        let requests = await probe.count
        XCTAssertEqual(requests, 1)
    }

    func testSamplerKeepsQuotesSeparateAcrossSubscribedSymbols() async {
        let probe = QuoteProbe()
        let sampler = FinnhubBidAskSampler { symbol, _ in
            await probe.load(symbol: symbol)
        }

        let apple = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 100_000)
        let microsoftBeforeRequest = await sampler.latest(symbol: "MSFT", apiKey: "fixture", nowMillis: 120_000)
        let microsoft = await sampler.latest(symbol: "MSFT", apiKey: "fixture", nowMillis: 160_000)
        let appleAfterRequest = await sampler.latest(symbol: "AAPL", apiKey: "fixture", nowMillis: 170_000)

        XCTAssertEqual(apple?.symbol, "AAPL")
        XCTAssertNil(microsoftBeforeRequest)
        XCTAssertEqual(microsoft?.symbol, "MSFT")
        XCTAssertEqual(appleAfterRequest?.symbol, "AAPL")
        let requests = await probe.count
        XCTAssertEqual(requests, 2)
    }
}

private actor QuoteProbe {
    private(set) var count = 0
    private let accessUnavailable: Bool

    init(accessUnavailable: Bool = false) {
        self.accessUnavailable = accessUnavailable
    }

    func load(symbol: String) -> ProviderQuoteSnapshot {
        count += 1
        return ProviderQuoteSnapshot(
            provider: "FINNHUB", symbol: symbol, identifier: symbol,
            currency: "USD", last: 100, bid: 99.9, ask: 100.1,
            bidSize: nil, askSize: nil, sessionVolume: nil,
            sessionTurnover: nil, averagePrice: nil, executions: nil,
            sessionHigh: nil, sessionLow: nil, previousClose: nil,
            observedAtMillis: 100_000
        )
    }

    func loadOrThrow(symbol: String) throws -> ProviderQuoteSnapshot {
        if accessUnavailable {
            count += 1
            throw FinnhubBidAskError.accessUnavailable
        }
        return load(symbol: symbol)
    }
}
