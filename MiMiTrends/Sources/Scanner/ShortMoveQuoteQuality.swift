import Foundation

enum ShortMoveQuoteQuality {
    static func acceptable(
        _ quote: ProviderQuoteSnapshot,
        marketPrice: Double,
        convertedMidpoint: (Double) -> Double?
    ) -> Bool {
        guard let bid = quote.bid, let ask = quote.ask else { return true }
        guard bid.isFinite, ask.isFinite, bid > 0, ask >= bid,
              marketPrice.isFinite, marketPrice > 0 else { return false }
        let midpoint = (bid + ask) / 2
        guard (ask - bid) / midpoint * 100 <= 0.30 else { return false }
        guard let converted = convertedMidpoint(midpoint) else { return true }
        return converted.isFinite && abs(converted / marketPrice - 1) * 100 <= 2.0
    }
}
