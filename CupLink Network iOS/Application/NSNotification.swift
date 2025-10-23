//
//  NSNotification.swift
//  CupLinkNetwork
//
//  Created by Neil Alexander on 20/02/2019.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Notification.Name {
    static let CupLinkSelfUpdated = Notification.Name("CupLinkSelfUpdated")
    static let CupLinkPeersUpdated = Notification.Name("CupLinkPeersUpdated")
    static let CupLinkSettingsUpdated = Notification.Name("CupLinkSettingsUpdated")
    static let CupLinkDHTUpdated = Notification.Name("CupLinkDHTUpdated")
}
