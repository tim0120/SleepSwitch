import Foundation

public enum SleepStatus: Equatable, Sendable {
    case blocked
    case normal
    case unknown(String)

    public var isBlocked: Bool {
        self == .blocked
    }

    public var menuTitle: String {
        switch self {
        case .blocked: "Sleep is blocked"
        case .normal: "Sleep is normal"
        case .unknown: "Sleep status unknown"
        }
    }

    public static func parse(_ output: String) -> SleepStatus {
        for line in output.components(separatedBy: .newlines) {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            guard let key = fields.first?.lowercased(),
                  key == "sleepdisabled" || key == "disablesleep" else { continue }
            guard fields.count >= 2 else {
                return .unknown("pmset reported a sleep setting without a value.")
            }
            switch fields[1] {
            case "1": return .blocked
            case "0": return .normal
            default: return .unknown("pmset reported an unexpected sleep value: \(fields[1]).")
            }
        }
        return .unknown("pmset output did not include SleepDisabled.")
    }
}
