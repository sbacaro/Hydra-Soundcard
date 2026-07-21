// Hydra Audio — GPL-3.0
// Network utility helpers for interface querying and filtering.

import Foundation
import SystemConfiguration

public enum NetworkUtils {
    /// Returns a set containing the BSD names (e.g. "en0") of all Wi-Fi (IEEE80211)
    /// interfaces active on the system. Used to exclude wireless interfaces from
    /// low-latency wired audio-over-IP networking.
    public static var wifiInterfaces: Set<String> {
        var names = Set<String>()
        if let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
            for interface in interfaces {
                if let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
                   let type = SCNetworkInterfaceGetInterfaceType(interface) as String?,
                   type == kSCNetworkInterfaceTypeIEEE80211 as String {
                    names.insert(bsdName)
                }
            }
        }
        return names
    }
}
