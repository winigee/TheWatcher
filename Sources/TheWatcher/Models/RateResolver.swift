import Foundation

/// Implements the strict hierarchical rate fallback described in §2.2 of the
/// specification. Rates are resolved at the moment a time entry is created and
/// then frozen onto the entry's `appliedRate`.
///
/// Resolution order (first match wins):
///   1. Entry-level manual override
///   2. Matter-level negotiated rate
///   3. Client-level global rate
///   4. Fee Earner default `baseRate`
public enum RateResolver {

    /// Identifies which level of the hierarchy supplied the resolved rate.
    /// Useful for surfacing provenance in the UI ("inherited from client").
    public enum Source: Equatable {
        case entryOverride
        case matter
        case client
        case feeEarnerDefault

        public var label: String {
            switch self {
            case .entryOverride: return "Entry override"
            case .matter: return "Matter rate"
            case .client: return "Client rate"
            case .feeEarnerDefault: return "Default rate"
            }
        }
    }

    public struct Resolution: Equatable {
        public let rate: Double
        public let source: Source
    }

    /// Resolves the effective rate given the optional overrides at each level.
    ///
    /// - Parameters:
    ///   - entryOverride: A rate the fee earner set on this specific entry.
    ///   - matterRate: The matter's negotiated rate, if any.
    ///   - clientRate: The client's global rate, if any.
    ///   - feeEarnerBaseRate: The always-present default fallback.
    public static func resolve(
        entryOverride: Double?,
        matterRate: Double?,
        clientRate: Double?,
        feeEarnerBaseRate: Double
    ) -> Resolution {
        if let entryOverride {
            return Resolution(rate: entryOverride, source: .entryOverride)
        }
        if let matterRate {
            return Resolution(rate: matterRate, source: .matter)
        }
        if let clientRate {
            return Resolution(rate: clientRate, source: .client)
        }
        return Resolution(rate: feeEarnerBaseRate, source: .feeEarnerDefault)
    }

    /// Convenience overload that reads the inherited rates directly from the
    /// model graph. The entry override is passed explicitly because it is a
    /// transient choice made during entry creation.
    public static func resolve(
        for matter: Matter,
        entryOverride: Double? = nil,
        feeEarner: FeeEarner
    ) -> Resolution {
        resolve(
            entryOverride: entryOverride,
            matterRate: matter.overrideRateValue,
            clientRate: matter.client?.overrideRateValue,
            feeEarnerBaseRate: feeEarner.baseRate
        )
    }
}
