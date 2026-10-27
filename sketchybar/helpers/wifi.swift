// Wi-Fi state for the bar, as one line of JSON.
//
//   wifi            {"power":true,"connected":true,"rssi":-58,"noise":-92,"tx":288,"ip":"192.168.0.7"}
//   wifi power on   turn the radio on (or off)
//
// The network name is left out on purpose: since macOS 14 CoreWLAN redacts the
// SSID for processes without Location access, while power, RSSI and rates
// stay readable.

import CoreWLAN
import Foundation

guard let iface = CWWiFiClient.shared().interface() else {
  print("{\"power\":false,\"connected\":false}")
  exit(0)
}

let args = CommandLine.arguments
if args.count == 3 && args[1] == "power" {
  do {
    try iface.setPower(args[2] == "on")
  } catch {
    FileHandle.standardError.write("\(error.localizedDescription)\n".data(using: .utf8)!)
    exit(1)
  }
  exit(0)
}

// Not associated: CoreWLAN reports an RSSI of 0 and no BSSID-backed channel.
let power = iface.powerOn()
let rssi = iface.rssiValue()
let connected = power && rssi != 0 && iface.wlanChannel() != nil

var ip = ""
if let name = iface.interfaceName {
  var addrs: UnsafeMutablePointer<ifaddrs>?
  if getifaddrs(&addrs) == 0 {
    var cursor = addrs
    while let entry = cursor?.pointee {
      if String(cString: entry.ifa_name) == name,
         entry.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(entry.ifa_addr, socklen_t(entry.ifa_addr.pointee.sa_len),
                    &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
        ip = String(cString: host)
      }
      cursor = entry.ifa_next
    }
    freeifaddrs(addrs)
  }
}

print("{\"power\":\(power),\"connected\":\(connected),\"rssi\":\(rssi),"
      + "\"noise\":\(iface.noiseMeasurement()),\"tx\":\(Int(iface.transmitRate())),"
      + "\"ip\":\"\(ip)\"}")
