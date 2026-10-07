import AppKit
import Carbon
import Foundation
import SleepSwitchCore

private enum PowerChangeResult {
    case success
    case failure(String)
}

private enum Shell {
    struct Result {
        let output: String
        let status: Int32
    }

    static func run(_ executable: String, _ arguments: [String]) throws -> Result {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(data: data, encoding: .utf8) ?? ""
        return Result(output: output, status: process.terminationStatus)
    }
}

private final class SleepPowerController {
    func readStatus() -> SleepStatus {
        do {
            let result = try Shell.run("/usr/bin/pmset", ["-g"])
            guard result.status == 0 else {
                return .unknown(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            return SleepStatus.parse(result.output)
        } catch {
            return .unknown(error.localizedDescription)
        }
    }

    func setSleepBlocked(_ blocked: Bool) -> PowerChangeResult {
        let value = blocked ? "1" : "0"
        let passwordlessResult = runPasswordlessPmset(value: value)
        if passwordlessResult.status == 0 {
            return .success
        }

        let command = "/usr/bin/pmset -a disablesleep \(value)"
        let script = #"do shell script "\#(escapeForAppleScript(command))" with administrator privileges"#

        do {
            let result = try Shell.run("/usr/bin/osascript", ["-e", script])
            if result.status == 0 {
                return .success
            }

            let message = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failure(message.isEmpty ? "pmset failed with status \(result.status)." : message)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func runPasswordlessPmset(value: String) -> Shell.Result {
        do {
            return try Shell.run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", value])
        } catch {
            return Shell.Result(output: error.localizedDescription, status: 1)
        }
    }

    private func escapeForAppleScript(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Checking sleep status...", action: nil, keyEquivalent: "")
    private let toggleMenuItem = NSMenuItem(title: "Toggle Sleep Blocker", action: #selector(toggleSleepBlocked), keyEquivalent: "s")
    private let controller = SleepPowerController()

    private var hotKeyRef: EventHotKeyRef?
    private var isChanging = false
    private var lastStatus: SleepStatus = .unknown("App has not checked yet.")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMenu()
        registerHotKey()
        refreshStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshStatus()
    }

    private func configureStatusItem() {
        statusItem.button?.image = makeIcon(blocked: false, unknown: true)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.toolTip = "SleepSwitch"
    }

    private func configureMenu() {
        statusMenuItem.isEnabled = false

        toggleMenuItem.target = self
        toggleMenuItem.keyEquivalentModifierMask = [.control, .option, .command]
        menu.autoenablesItems = false

        // Status refreshes automatically in menuWillOpen, so no manual
        // refresh item; utility shortcuts stay out of the status menu.
        menu.delegate = self
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(toggleMenuItem)
        menu.addItem(.separator())
        let aboutItem = NSMenuItem(title: "About SleepSwitch", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem(title: "Quit SleepSwitch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func refreshStatus() {
        guard !isChanging else { return }
        lastStatus = controller.readStatus()
        renderStatus()
    }

    @objc private func toggleSleepBlocked() {
        guard !isChanging else { return }

        let currentStatus = controller.readStatus()
        lastStatus = currentStatus
        if case .unknown(let message) = currentStatus {
            renderStatus()
            showAlert(title: "Sleep status unavailable", body: message)
            return
        }
        let shouldBlock = !currentStatus.isBlocked

        setChanging(true, targetBlocked: shouldBlock)

        let result = controller.setSleepBlocked(shouldBlock)
        setChanging(false, targetBlocked: shouldBlock)

        switch result {
        case .success:
            lastStatus = controller.readStatus()
            renderStatus()
        case .failure(let message):
            lastStatus = controller.readStatus()
            renderStatus()
            showAlert(title: "SleepSwitch could not toggle sleep", body: message)
        }
    }

    private func setChanging(_ changing: Bool, targetBlocked: Bool) {
        isChanging = changing
        toggleMenuItem.isEnabled = !changing

        if changing {
            statusMenuItem.title = targetBlocked ? "Blocking sleep..." : "Restoring normal sleep..."
            toggleMenuItem.title = "Waiting for admin confirmation..."
            statusItem.button?.image = makeIcon(blocked: targetBlocked, unknown: true)
            statusItem.button?.toolTip = "SleepSwitch is updating pmset"
        } else {
            renderStatus()
        }
    }

    private func renderStatus() {
        statusMenuItem.title = lastStatus.menuTitle

        switch lastStatus {
        case .blocked:
            toggleMenuItem.title = "Restore Normal Sleep"
            statusItem.button?.image = makeIcon(blocked: true, unknown: false)
            statusItem.button?.toolTip = "Sleep blocked system-wide; the setting persists after quitting"
        case .normal:
            toggleMenuItem.title = "Block Sleep"
            statusItem.button?.image = makeIcon(blocked: false, unknown: false)
            statusItem.button?.toolTip = "Sleep normal: close-lid sleep is allowed"
        case .unknown(let message):
            toggleMenuItem.title = "Sleep Status Unavailable"
            statusItem.button?.image = makeIcon(blocked: false, unknown: true)
            statusItem.button?.toolTip = "Sleep status unknown: \(message)"
        }
        if case .unknown = lastStatus {
            toggleMenuItem.isEnabled = false
        } else {
            toggleMenuItem.isEnabled = !isChanging
        }
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: "Free and open source • MIT license\nhttps://github.com/tim0120/SleepSwitch\n\nSleepSwitch changes a system-wide power setting. Restore Normal Sleep before putting your Mac in a bag. Quitting the app does not restore sleep.")
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    private func registerHotKey() {
        let eventTarget = GetApplicationEventTarget()
        let hotKeyID = EventHotKeyID(signature: OSType(0x53575357), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(
            eventTarget,
            { _, _, _ in
                Task { @MainActor in
                    AppDelegate.current?.toggleSleepBlocked()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        let modifiers = UInt32(cmdKey | optionKey | controlKey)
        let sKeyCode: UInt32 = 1
        let status = RegisterEventHotKey(sKeyCode, modifiers, hotKeyID, eventTarget, 0, &hotKeyRef)

        if status != noErr {
            showAlert(title: "SleepSwitch hotkey unavailable", body: "Control-Option-Command-S could not be registered.")
        }
    }

    private func showAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func makeIcon(blocked: Bool, unknown: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let bounds = rect.insetBy(dx: 2.5, dy: 2.5)
            let color = NSColor.labelColor
            color.setStroke()
            color.setFill()

            let moonPath = NSBezierPath()
            moonPath.appendArc(
                withCenter: CGPoint(x: bounds.midX + 1.8, y: bounds.midY + 0.5),
                radius: 5.7,
                startAngle: 72,
                endAngle: 288,
                clockwise: false
            )
            moonPath.appendArc(
                withCenter: CGPoint(x: bounds.midX + 4.4, y: bounds.midY + 1.1),
                radius: 5.2,
                startAngle: 250,
                endAngle: 105,
                clockwise: true
            )
            moonPath.close()
            moonPath.lineWidth = 1.4
            moonPath.stroke()

            if blocked {
                let slash = NSBezierPath()
                slash.move(to: CGPoint(x: bounds.minX + 1.0, y: bounds.minY + 1.0))
                slash.line(to: CGPoint(x: bounds.maxX - 1.0, y: bounds.maxY - 1.0))
                slash.lineWidth = 2.0
                slash.stroke()
            }

            if unknown {
                let dotRect = CGRect(x: bounds.maxX - 2.6, y: bounds.minY, width: 2.3, height: 2.3)
                NSBezierPath(ovalIn: dotRect).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    private static weak var current: AppDelegate?

    override init() {
        super.init()
        Self.current = self
    }
}

// Read-only diagnostics for build/release checks; never change power settings.
if CommandLine.arguments.contains("--status") {
    let status = SleepPowerController().readStatus()
    print(status.menuTitle)
    if case .unknown(let message) = status {
        fputs("\(message)\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) {
        app.run()
    }
}
