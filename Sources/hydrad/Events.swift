// Hydra Audio — GPL-3.0
// Event center: managers emit user-relevant events (drops, blocks, failures);
// the daemon keeps a short ring and pushes them live to clients (Section 6,
// "event log" — discreet notices, never modal interruptions).

import Foundation
import HydraCore

final class EventCenter: @unchecked Sendable {
    static let shared = EventCenter()

    private let queue = DispatchQueue(label: "hydra.events")
    private var buffer: [HydraEvent] = []
    private let capacity = 50
    /// Wired by main to broadcast each new event.
    var onEvent: ((HydraEvent) -> Void)?

    func emit(_ kind: HydraEvent.Kind, _ message: String) {
        let event = HydraEvent(kind: kind, message: message)
        queue.sync {
            buffer.append(event)
            if buffer.count > capacity {
                buffer.removeFirst(buffer.count - capacity)
            }
        }
        log("Event [\(kind.rawValue)]: \(message)")
        // Dispatch the broadcast from the events queue so concurrent calls from
        // multiple manager queues (hydra.devices, hydra.bridges, …) are serialised
        // and the WebSocketServer's send path is never entered from two threads at once.
        queue.async { [weak self] in
            self?.onEvent?(event)
        }
    }

    func recent() -> [HydraEvent] {
        queue.sync { buffer }
    }
}
