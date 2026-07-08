import Foundation

@MainActor
class DanteClockBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    static let shared = DanteClockBrowser()
    private let browser = NetServiceBrowser()
    private var services = Set<NetService>()
    private var timer: Timer?
    
    var onMasterDiscovered: ((String) -> Void)?
    
    override init() {
        super.init()
    }
    
    func start() {
        browser.delegate = self
        browser.searchForServices(ofType: "_netaudio-cmc._udp", inDomain: "local.")
        
        // Periodically refresh search to discover new devices
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.browser.stop()
                self.services.removeAll()
                self.browser.searchForServices(ofType: "_netaudio-cmc._udp", inDomain: "local.")
            }
        }
    }
    
    func stop() {
        browser.stop()
        timer?.invalidate()
        timer = nil
        services.removeAll()
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.insert(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.remove(service)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let txtData = sender.txtRecordData() else { return }
        let dict = NetService.dictionary(fromTXTRecord: txtData)
        
        if let idData = dict["id"], let idStr = String(data: idData, encoding: .utf8) {
            let name = sender.name
            // Ignore ourselves and other virtual/software instances running on the same Mac
            let localHostName = ProcessInfo.processInfo.hostName
            if name.contains("Hydra") || name.contains("PC-AV") || name.contains(localHostName) {
                return
            }
            log("DanteClockBrowser: Found hardware master candidate \(name) with clock ID \(idStr)")
            onMasterDiscovered?(idStr)
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        services.remove(sender)
    }
}
