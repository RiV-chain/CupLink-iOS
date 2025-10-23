//
//  AppDelegateExtension.swift
//  CupLink Network
//
//  Created by Neil Alexander on 11/01/2019.
//

import Foundation
import NetworkExtension
import CupLink
import UIKit

class CrossPlatformAppDelegate: PlatformAppDelegate {
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()

    #if os(iOS)
    let CupLinkComponent = "eu.neilalexander.CupLink.extension"
    #elseif os(OSX)
    let CupLinkComponent = "eu.neilalexander.CupLinkmac.extension"
    #endif
    
    var CupLinkConfig: ConfigurationProxy? = nil
    
    var CupLinkAdminTimer: DispatchSourceTimer?
    
    var CupLinkSelfIP: String = "N/A"
    var CupLinkSelfSubnet: String = "N/A"
    var CupLinkSelfCoords: String = "[]"

    var CupLinkPeers: [[String: Any]] = [[:]]
    var CupLinkDHT: [[String: Any]] = [[:]]
    var CupLinkNodeInfo: [String: Any] = [:]
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if self.CupLinkAdminTimer == nil {
            self.CupLinkAdminTimer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue(label: "Admin Queue"))
            self.CupLinkAdminTimer!.schedule(deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(2), leeway: DispatchTimeInterval.seconds(1))
            self.CupLinkAdminTimer!.setEventHandler {
                self.makeIPCRequests()
            }
        }
        if self.CupLinkAdminTimer != nil {
            self.CupLinkAdminTimer!.resume()
        }
        NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: nil, using: { notification in
            if let conn = notification.object as? NEVPNConnection {
                self.updateStatus(conn: conn)
            }
        })
        self.updateStatus(conn: self.vpnManager.connection)
    }
    
    func updateStatus(conn: NEVPNConnection) {
        if conn.status == .connected {
            self.makeIPCRequests()
        } else if conn.status == .disconnecting || conn.status == .disconnected {
            self.clearStatus()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        if self.CupLinkAdminTimer != nil {
            self.CupLinkAdminTimer!.suspend()
        }
    }
    
    func vpnTunnelProviderManagerInit() {
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            
            if let savedManagers = savedManagers {
                for manager in savedManagers {
                    if (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == self.CupLinkComponent {
                        print("Found saved VPN Manager")
                        self.vpnManager = manager
                    }
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error: Error?) in
                if let error = error {
                    print(error)
                }
                
                if let vpnConfig = self.vpnManager.protocolConfiguration as? NETunnelProviderProtocol,
                    let confJson = vpnConfig.providerConfiguration!["json"] as? Data {
                    print("Found existing protocol configuration")
                    self.CupLinkConfig = try? ConfigurationProxy(json: confJson)
                } else  {
                    print("Generating new protocol configuration")
                    self.CupLinkConfig = ConfigurationProxy()
                }
                
                self.vpnManager.localizedDescription = "CupLink"
                self.vpnManager.isEnabled = true
                
                if let config = self.CupLinkConfig {
                    try? config.save(to: &self.vpnManager)
                }
            })
        }
    }
    
    func makeIPCRequests() {
        if self.vpnManager.connection.status != .connected {
            return
        }
        if let session = self.vpnManager.connection as? NETunnelProviderSession {
            try? session.sendProviderMessage("address".data(using: .utf8)!) { (address) in
                if let address = address {
                    self.CupLinkSelfIP = String(data: address, encoding: .utf8)!
                    NotificationCenter.default.post(name: .CupLinkSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("subnet".data(using: .utf8)!) { (subnet) in
                if let subnet = subnet {
                    self.CupLinkSelfSubnet = String(data: subnet, encoding: .utf8)!
                    NotificationCenter.default.post(name: .CupLinkSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("coords".data(using: .utf8)!) { (coords) in
                if let coords = coords {
                    self.CupLinkSelfCoords = String(data: coords, encoding: .utf8)!
                    NotificationCenter.default.post(name: .CupLinkSelfUpdated, object: nil)
                }
            }
            try? session.sendProviderMessage("peers".data(using: .utf8)!) { (peers) in
                if let peers = peers {
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: peers, options: []) as? [[String: Any]] {
                        self.CupLinkPeers = jsonResponse
                        NotificationCenter.default.post(name: .CupLinkPeersUpdated, object: nil)
                    }
                }
            }
            try? session.sendProviderMessage("dht".data(using: .utf8)!) { (peers) in
                if let peers = peers {
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: peers, options: []) as? [[String: Any]] {
                        self.CupLinkDHT = jsonResponse
                        NotificationCenter.default.post(name: .CupLinkDHTUpdated, object: nil)
                    }
                }
            }
        }
    }
    
    func clearStatus() {
        self.CupLinkSelfIP = "N/A"
        self.CupLinkSelfSubnet = "N/A"
        self.CupLinkSelfCoords = "[]"
        self.CupLinkPeers = []
        self.CupLinkDHT = []
        NotificationCenter.default.post(name: .CupLinkSelfUpdated, object: nil)
        NotificationCenter.default.post(name: .CupLinkPeersUpdated, object: nil)
        NotificationCenter.default.post(name: .CupLinkDHTUpdated, object: nil)
    }
}
