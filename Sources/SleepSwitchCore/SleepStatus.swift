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
        var hasLiveSettings = false
        var hasSleepTimer = false
        for line in output.components(separatedBy: .newlines) {
            let fields = line.split(whereSeparator: { $0.isWhitespace })
            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "Currently in use:" {
                hasLiveSettings = true
            }
            if fields.first == "sleep", fields.count >= 2,
               let timer = Int(fields[1]), timer >= 0 {
                hasSleepTimer = true
            }
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
        // pmset prints only saved system-wide overrides. A readable live settings
        // section without a SleepDisabled override uses macOS's default (off).
        // See Apple's PowerManagement/pmset and PMSettings source.
        if hasLiveSettings && hasSleepTimer {
            return .normal
        }
        return .unknown("pmset output did not include SleepDisabled.")
    }
}
