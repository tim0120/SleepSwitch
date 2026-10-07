import Foundation

// Compiled with the actual core source by Scripts/test.sh. No test framework or
// full Xcode installation is required, and no power settings are changed.
let cases: [(String, SleepStatus, String)] = [
    ("System-wide power settings:\n SleepDisabled\t\t1\nCurrently in use:\n sleep 0 (sleep prevented by another app)\n", .blocked, "system setting takes priority over idle sleep timer"),
    ("System-wide power settings:\n SleepDisabled 0\nCurrently in use:\n sleep 0\n", .normal, "zero idle sleep timer does not mean system sleep is blocked"),
    ("\tdisablesleep\t1\r\n", .blocked, "alternate setting key and CRLF"),
    (" SLEEPDISABLED   0 ", .normal, "case and whitespace"),
    ("Currently in use:\n standby 1\n sleep 20\n displaysleep 10\n", .normal, "fresh macOS defaults without a saved system override"),
    ("Currently in use:\n sleep 0 (sleep prevented by another app)\n", .normal, "an idle-sleep assertion does not enable the system switch"),
    ("Currently in use:\n", .unknown("pmset output did not include SleepDisabled."), "truncated live settings are not defaults"),
    ("sleep 0", .unknown("pmset output did not include SleepDisabled."), "missing system setting"),
    ("SleepDisabled 2", .unknown("pmset reported an unexpected sleep value: 2."), "invalid value cannot imply normal sleep"),
    ("Currently in use:\n sleep 20\n SleepDisabled 2\n", .unknown("pmset reported an unexpected sleep value: 2."), "invalid explicit override takes priority over defaults"),
    ("SleepDisabled", .unknown("pmset reported a sleep setting without a value."), "truncated output"),
    ("", .unknown("pmset output did not include SleepDisabled."), "empty output")
]
for (input, expected, scenario) in cases {
    let actual = SleepStatus.parse(input)
    guard actual == expected else {
        FileHandle.standardError.write(Data("FAIL: \(scenario): expected \(expected), got \(actual)\n".utf8))
        exit(1)
    }
}
print("Passed \(cases.count) sleep-status checks without changing power settings.")
