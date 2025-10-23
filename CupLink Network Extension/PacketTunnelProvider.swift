import NetworkExtension
import Foundation
import Mesh

class PacketTunnelProvider: NEPacketTunnelProvider {

    var Mesh: MobileMesh = MobileMesh()
    var CupLinkConfig: ConfigurationProxy?

    func startCupLink() -> Error? {
        var err: Error? = nil

        self.setTunnelNetworkSettings(nil) { (error: Error?) -> Void in
            NSLog("Starting CupLink")
            
            if let error = error {
                NSLog("Failed to clear CupLink tunnel network settings: " + error.localizedDescription)
                err = error
            }
            if self.CupLinkConfig == nil {
                NSLog("No configuration proxy!")
                return
            }
            if let config = self.CupLinkConfig {
                NSLog("Configuration loaded")
                
                do {
                    try self.Mesh.startJSON(config.data())
                } catch {
                    NSLog("Starting CupLink process produced an error: " + error.localizedDescription)
                    return
                }

                let address = self.Mesh.getAddressString()
                let subnet = self.Mesh.getSubnetString()
                
                NSLog("CupLink IPv6 address: " + address)
                NSLog("CupLink IPv6 subnet: " + subnet)
                
                let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: address)
                tunnelNetworkSettings.ipv6Settings = NEIPv6Settings(addresses: [address], networkPrefixLengths: [7])
                tunnelNetworkSettings.ipv6Settings?.includedRoutes = [NEIPv6Route(destinationAddress: "0200::", networkPrefixLength: 7)]
                tunnelNetworkSettings.mtu = NSNumber(integerLiteral: self.Mesh.getMTU())

                NSLog("Setting tunnel network settings...")
                
                self.setTunnelNetworkSettings(tunnelNetworkSettings) { (error: Error?) -> Void in
                    NSLog("setTunnelNetworkSettings completed successfully")
                    if let error = error {
                        NSLog("Failed to set CupLink tunnel network settings: " + error.localizedDescription)
                        err = error
                    } else {
                        NSLog("CupLink tunnel settings set successfully")
                        
                        if let fd = self.tunnelFileDescriptor {
                            do {
                                try self.Mesh.takeOverTUN(fd)
                            } catch {
                                NSLog("Taking over TUN produced an error: " + error.localizedDescription)
                                err = error
                            }
                        }
                    }
                }
            }
        }
        return err
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let conf = (self.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration {
            if let json = conf["json"] as? Data {
                do {
                    self.CupLinkConfig = try ConfigurationProxy(json: json)
                } catch {
                    NSLog("Error in CupLink startTunnel: Configuration is invalid")
                    return
                }
                if let error = self.startCupLink() {
                    NSLog("Error in CupLink startTunnel: " + error.localizedDescription)
                } else {
                    NSLog("CupLink completion handler called")
                    completionHandler(nil)
                }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        try? self.Mesh.stop()
        super.stopTunnel(with: reason, completionHandler: completionHandler)
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        let request = String(data: messageData, encoding: .utf8)
        switch request {
        case "address":
            completionHandler?(self.Mesh.getAddressString().data(using: .utf8))
        case "subnet":
            completionHandler?(self.Mesh.getSubnetString().data(using: .utf8))
        case "coords":
            completionHandler?(self.Mesh.getCoordsString().data(using: .utf8))
        case "peers":
            completionHandler?(self.Mesh.getPeersJSON().data(using: .utf8))
        case "dht":
            completionHandler?(self.Mesh.getDHTJSON().data(using: .utf8))
        default:
            completionHandler?(nil)
        }
    }
}
