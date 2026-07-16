import Foundation
import AppKit

enum InstallerEngine {

    static var activeCancelFile: String?
    static var activePidFile: String?

    static func requestCancellation() {
        if let f = activeCancelFile {
            try? "1".write(toFile: f, atomically: true, encoding: .utf8)
        }
    }

    @MainActor
    static func runInstallation(
        components: [Component],
        uninstallExisting: Bool,
        existingComponents: [Component],
        uninstallOnly: Bool = false,
        onLog: @escaping (String) -> Void,
        onComponentStatusChange: @escaping (String, ComponentStatus) -> Void,
        onOverallProgress: @escaping (Double) -> Void,
        onCurrentChange: @escaping (String?) -> Void
    ) async -> (succeeded: [String], failed: [String], skipped: [String]) {

        let statusFile = "/tmp/Hydra_Installer_Status.log"
        let scriptFile = "/tmp/Hydra_Installer_Run.sh"
        let cancelFile = "/tmp/Hydra_Installer_Cancel.flag"
        let pidFile = "/tmp/Hydra_Installer_Run.pid"
        let logFile = NSHomeDirectory() + "/Library/Logs/Hydra Installer.log"

        // Resolve payload path inside our bundle
        guard let payloadURL = Bundle.main.resourceURL?.appendingPathComponent("payload") else {
            onLog("✗ Internal error: payload directory not found in installer bundle.")
            return (succeeded: [], failed: components.map { $0.id }, skipped: [])
        }
        let payloadPath = payloadURL.path

        try? FileManager.default.createDirectory(atPath: (logFile as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: cancelFile)
        try? FileManager.default.removeItem(atPath: pidFile)
        try? "".write(toFile: statusFile, atomically: true, encoding: .utf8)

        InstallerEngine.activeCancelFile = cancelFile
        InstallerEngine.activePidFile = pidFile

        onLog(uninstallOnly ? "Starting uninstallation session" : "Starting installation session")
        onLog("Payload directory: \(payloadPath)")
        onLog("Log file: \(logFile)")

        // Build script
        let script = buildInstallerScript(
            components: components,
            uninstallExisting: uninstallExisting,
            existingComponents: existingComponents,
            uninstallOnly: uninstallOnly,
            statusFile: statusFile,
            logFile: logFile,
            cancelFile: cancelFile,
            pidFile: pidFile
        )

        do {
            try script.write(toFile: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptFile)
        } catch {
            onLog("Failed to write installer script: \(error.localizedDescription)")
            return (succeeded: [], failed: components.map { $0.id }, skipped: [])
        }

        onLog("Requesting administrator privileges…")

        let executionResult = AppleScriptResult()
        let executionGroup = DispatchGroup()
        executionGroup.enter()

        DispatchQueue.global(qos: .userInitiated).async {
            defer { executionGroup.leave() }
            let (success, errorMsg) = runPrivilegedAppleScriptBlocking(
                scriptPath: scriptFile,
                payloadPath: payloadPath,
                logFile: logFile
            )
            executionResult.set(success: success, errorMessage: errorMsg)
        }

        var statusOffset = 0
        var seenLines: Set<String> = []
        var succeeded: [String] = []
        var failed: [String] = []
        var skipped: [String] = []
        var done = false
        var scriptObservedRunning = false
        var startTime = Date()

        while !done {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

            if let data = try? String(contentsOfFile: statusFile, encoding: .utf8),
               data.count > statusOffset {
                let newPart = String(data.dropFirst(statusOffset))
                statusOffset = data.count
                let lines = newPart.split(separator: "\n").map(String.init)
                for line in lines where !line.isEmpty && !seenLines.contains(line) {
                    seenLines.insert(line)
                    scriptObservedRunning = true
                    parseStatus(
                        line: line,
                        components: components,
                        onLog: onLog,
                        onComponentStatusChange: onComponentStatusChange,
                        onCurrentChange: onCurrentChange,
                        onOverallProgress: onOverallProgress,
                        onSuccess: { id in
                            failed.removeAll { $0 == id }
                            if !succeeded.contains(id) { succeeded.append(id) }
                        },
                        onFailure: { id in
                            if succeeded.contains(id) { return }
                            if !failed.contains(id) { failed.append(id) }
                        },
                        onSkipped: { id in
                            if !skipped.contains(id) { skipped.append(id) }
                        },
                        onDone: { done = true }
                    )
                }
            }

            if !scriptObservedRunning {
                let elapsed = Date().timeIntervalSince(startTime)
                let pidExists = FileManager.default.fileExists(atPath: pidFile)
                if elapsed > 4 && !pidExists && executionResult.isFinished {
                    onLog("⚠️ The installer script did not start.")
                    if let err = executionResult.errorMessage {
                        onLog("Reason: \(err)")
                    } else {
                        onLog("Reason: authorization may have been denied or the script failed to launch.")
                    }
                    break
                }
                if elapsed > 8 && !pidExists {
                    onLog("⚠️ Still waiting for the privileged script to start (PID file not present)…")
                    startTime = Date()
                }
            }

            if executionResult.isFinished && !done {
                try? await Task.sleep(nanoseconds: 250_000_000)
                if let data = try? String(contentsOfFile: statusFile, encoding: .utf8),
                   data.count > statusOffset {
                    let newPart = String(data.dropFirst(statusOffset))
                    statusOffset = data.count
                    for line in newPart.split(separator: "\n").map(String.init)
                        where !line.isEmpty && !seenLines.contains(line) {
                        seenLines.insert(line)
                        parseStatus(
                            line: line,
                            components: components,
                            onLog: onLog,
                            onComponentStatusChange: onComponentStatusChange,
                            onCurrentChange: onCurrentChange,
                            onOverallProgress: onOverallProgress,
                            onSuccess: { id in
                                failed.removeAll { $0 == id }
                                if !succeeded.contains(id) { succeeded.append(id) }
                            },
                            onFailure: { id in
                                if succeeded.contains(id) { return }
                                if !failed.contains(id) { failed.append(id) }
                            },
                            onSkipped: { id in
                                if !skipped.contains(id) { skipped.append(id) }
                            },
                            onDone: { done = true }
                        )
                    }
                }
                if !done {
                    onLog("Installation ended without a DONE signal.")
                    if let err = executionResult.errorMessage {
                        onLog("Reason: \(err)")
                    }
                    break
                }
            }
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            executionGroup.notify(queue: .global()) { cont.resume() }
        }

        try? FileManager.default.removeItem(atPath: scriptFile)
        try? FileManager.default.removeItem(atPath: cancelFile)
        try? FileManager.default.removeItem(atPath: pidFile)
        InstallerEngine.activeCancelFile = nil
        InstallerEngine.activePidFile = nil
        onCurrentChange(nil)
        onOverallProgress(1.0)

        return (succeeded: succeeded, failed: failed, skipped: skipped)
    }

    private final class AppleScriptResult: @unchecked Sendable {
        private let lock = NSLock()
        private var _success: Bool = false
        private var _errorMessage: String? = nil
        private var _finished: Bool = false

        var isFinished: Bool { lock.withLock { _finished } }
        var success: Bool { lock.withLock { _success } }
        var errorMessage: String? { lock.withLock { _errorMessage } }

        func set(success: Bool, errorMessage: String?) {
            lock.withLock {
                self._success = success
                self._errorMessage = errorMessage
                self._finished = true
            }
        }
    }

    private static func parseStatus(
        line: String,
        components: [Component],
        onLog: @escaping (String) -> Void,
        onComponentStatusChange: @escaping (String, ComponentStatus) -> Void,
        onCurrentChange: @escaping (String?) -> Void,
        onOverallProgress: @escaping (Double) -> Void,
        onSuccess: @escaping (String) -> Void,
        onFailure: @escaping (String) -> Void,
        onSkipped: @escaping (String) -> Void,
        onDone: @escaping () -> Void
    ) {
        let parts = line.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
        guard let tag = parts.first else { return }

        switch tag {
        case "LOG":
            onLog(parts.count >= 2 ? parts[1...].joined(separator: ":") : "")

        case "START":
            if parts.count >= 2 {
                onCurrentChange(parts[1])
            }

        case "INSTALLING":
            if parts.count >= 2 {
                onComponentStatusChange(parts[1], .installing)
            }

        case "OK":
            if parts.count >= 2 {
                onComponentStatusChange(parts[1], .installed)
                onSuccess(parts[1])
                onLog("✓ Installed \(parts[1])")
            }

        case "FAIL":
            if parts.count >= 2 {
                let reason = parts.count >= 3 ? parts[2] : "unknown error"
                onComponentStatusChange(parts[1], .failed(reason: reason))
                onFailure(parts[1])
                onLog("✗ Failed \(parts[1]): \(reason)")
            }

        case "SKIP":
            if parts.count >= 2 {
                onComponentStatusChange(parts[1], .skipped)
                onSkipped(parts[1])
                onLog("⤼ Skipped \(parts[1])")
            }

        case "PROGRESS":
            if parts.count >= 2, let p = Double(parts[1]) {
                onOverallProgress(p)
            }

        case "DONE":
            onDone()

        default:
            if !line.isEmpty {
                onLog(line)
            }
        }
    }

    private static func runPrivilegedAppleScriptBlocking(
        scriptPath: String,
        payloadPath: String,
        logFile: String
    ) -> (Bool, String?) {
        let escapedScript = scriptPath.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedPayload = payloadPath.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedLog = logFile.replacingOccurrences(of: "\"", with: "\\\"")

        let command = "\"\(escapedScript)\" \"\(escapedPayload)\" </dev/null >> \"\(escapedLog)\" 2>&1"
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")

        let appleScript = """
        do shell script "\(escapedCommand)" with administrator privileges with prompt "Hydra Installer needs administrator privileges to copy audio drivers and start services."
        """

        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: appleScript) else {
            return (false, "Could not construct AppleScript object.")
        }

        scriptObject.executeAndReturnError(&error)

        if let error = error {
            let errCode = error["NSAppleScriptErrorNumber"] as? Int ?? 0
            let errMsg = error["NSAppleScriptErrorMessage"] as? String ?? "unknown error"
            if errCode == -128 {
                return (false, "User cancelled the administrator prompt.")
            }
            return (false, "AppleScript error \(errCode): \(errMsg)")
        }
        return (true, nil)
    }

    private static func buildInstallerScript(
        components: [Component],
        uninstallExisting: Bool,
        existingComponents: [Component],
        uninstallOnly: Bool,
        statusFile: String,
        logFile: String,
        cancelFile: String,
        pidFile: String
    ) -> String {
        let componentArgs = components.map { "\"\($0.id)|\($0.pathInPayload)|\($0.destinationPath)\"" }.joined(separator: " ")
        let uninstallFlag = uninstallExisting ? "1" : "0"
        let uninstallOnlyFlag = uninstallOnly ? "1" : "0"
        let existingList = existingComponents.map { "\"\($0.id)|\($0.destinationPath)\"" }.joined(separator: " ")
        let totalComponents = components.count

        return #"""
        #!/bin/zsh

        STATUS_FILE="\#(statusFile)"
        LOG_FILE="\#(logFile)"
        CANCEL_FILE="\#(cancelFile)"
        PID_FILE="\#(pidFile)"
        TOTAL_COMPONENTS=\#(totalComponents)
        UNINSTALL_EXISTING=\#(uninstallFlag)
        UNINSTALL_ONLY=\#(uninstallOnlyFlag)

        echo $$ > "$PID_FILE" 2>/dev/null
        printf '%s\n' "LOG:Installer script process started (PID $$)" >> "$STATUS_FILE" 2>/dev/null
        printf '%s\n' "LOG:Running as $(/usr/bin/id -un 2>/dev/null), shell $ZSH_VERSION" >> "$STATUS_FILE" 2>/dev/null

        PAYLOAD_DIR="$1"
        shift 1

        COMPONENTS=(\#(componentArgs))
        EXISTING=(\#(existingList))

        ts() { date "+%Y-%m-%d %H:%M:%S"; }
        report() { printf '%s\n' "$1" >> "$STATUS_FILE"; }
        log() {
            local msg="$1"
            printf '[%s] %s\n' "$(ts)" "$msg" >> "$LOG_FILE"
            report "LOG:$msg"
        }
        is_cancelled() { [[ -f "$CANCEL_FILE" ]]; }

        cleanup_and_exit() {
            log "Received termination signal — cleaning up."
            report "LOG:Installation interrupted."
            report "DONE"
            exit 130
        }
        trap cleanup_and_exit TERM INT HUP

        # ── 1. Uninstallation phase ───────────────────────────────────────────
        if [[ "$UNINSTALL_EXISTING" == "1" || "$UNINSTALL_ONLY" == "1" ]]; then
            log "Starting uninstallation of existing Hydra components..."
            for item in "${EXISTING[@]}"; do
                local cid="${item%%|*}"
                local dest="${item#*|}"
                
                is_cancelled && break
                log "Removing: $dest"
                rm -rf "$dest"
            done
            
            # Restart coreaudiod if HAL drivers were removed
            log "Restarting CoreAudio service..."
            launchctl kickstart -k system/com.apple.audio.coreaudiod 2>/dev/null || killall -9 coreaudiod 2>/dev/null
            log "Uninstallation phase complete."
        fi

        if [[ "$UNINSTALL_ONLY" == "1" ]]; then
            report "PROGRESS:1.0"
            report "DONE"
            exit 0
        fi

        # ── 2. Installation phase ─────────────────────────────────────────────
        log "Starting installation of selected components..."
        local count=0
        for item in "${COMPONENTS[@]}"; do
            is_cancelled && break
            
            local cid="${item%%|*}"
            local remainder="${item#*|}"
            local payload_rel="${remainder%%|*}"
            local dest="${remainder#*|}"
            
            report "START:$cid"
            report "INSTALLING:$cid"
            
            log "Installing $cid to $dest"
            
            # Ensure destination parent directory exists
            local dest_parent
            dest_parent=$(dirname "$dest")
            mkdir -p "$dest_parent"
            
            # Remove any existing file/directory at the destination first
            rm -rf "$dest"
            
            # Copy payload
            local src="$PAYLOAD_DIR/$payload_rel"
            if [[ -d "$src" ]]; then
                cp -R "$src" "$dest"
            elif [[ -f "$src" ]]; then
                cp "$src" "$dest"
            else
                log "Error: Source payload not found: $src"
                report "FAIL:$cid:Payload missing"
                continue
            fi
            
            # Fix permissions for HAL drivers or applications
            if [[ "$dest" == *".driver" ]]; then
                log "Setting driver ownership and permissions on $dest"
                chown -R root:wheel "$dest"
                chmod -R 755 "$dest"
            fi
            
            report "OK:$cid"
            
            count=$((count + 1))
            local progress
            progress=$(awk "BEGIN{printf \"%.2f\", $count/$TOTAL_COMPONENTS}")
            report "PROGRESS:$progress"
        done

        # ── 3. Post-install ───────────────────────────────────────────────────
        if is_cancelled; then
            log "Installation cancelled by user."
        else
            log "Restarting CoreAudio service to load HAL drivers..."
            launchctl kickstart -k system/com.apple.audio.coreaudiod 2>/dev/null || killall -9 coreaudiod 2>/dev/null
            log "CoreAudio service restarted successfully."
            
            log "Hydra installation complete!"
            report "PROGRESS:1.0"
        fi

        report "DONE"
        exit 0
        """#
    }
}
