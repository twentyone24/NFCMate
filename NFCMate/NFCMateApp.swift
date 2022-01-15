//
//  NFCMateApp.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/14/22.
//

import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }

        // Confirm that the NSUserActivity object contains a valid NDEF message.
        let ndefMessage = userActivity.ndefMessagePayload
        guard ndefMessage.records.count > 0,
            ndefMessage.records[0].typeNameFormat != .empty else {
                return false
        }

        // Send the message to `MessagesTableViewController` for processing.
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            return false
        }

        navigationController.popToRootViewController(animated: true)
//        let messageTableViewController = navigationController.topViewController as? MessagesTableViewController
//        messageTableViewController?.addMessage(fromUserActivity: ndefMessage)

        return true
    }
    
}

@main
struct NFCMateApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { URL in
                    print(URL)
                }
        }
    }
}
