//
//  NFCpayloadContentVM.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/14/22.
//

import Foundation
import CoreNFC
import UIKit

class NFCVM: NSObject, ObservableObject {
    
    @Published var payloadContent = ""
    @Published var writePayloadContent = ""
    
    func readData() {
        NFCUtility.performAction(.readData) { data in
            let message: NFCNDEFMessage? = try? data.get()
            
            guard let message = message, let payload = message.records.first else {
                print("NO PAYLOAD")
                return
            }
            switch payload.typeNameFormat {
            case .nfcWellKnown:
                if let type = String(data: payload.type, encoding: .utf8) {
                    if let url = payload.wellKnownTypeURIPayload() {
                        self.payloadContent = "\(payload.typeNameFormat.description): \(type), \(url.absoluteString)"
                    } else {
                        self.payloadContent = "\(payload.typeNameFormat.description): \(type)"
                    }
                }
            case .absoluteURI:
                if let text = String(data: payload.payload, encoding: .utf8) {
                    self.payloadContent = text
                }
            case .media:
                if let type = String(data: payload.type, encoding: .utf8) {
                    self.payloadContent = "\(payload.typeNameFormat.description): " + type
                }
            case .nfcExternal, .empty, .unknown, .unchanged:
                fallthrough
            @unknown default:
                self.payloadContent = payload.typeNameFormat.description
            }
        }
    }
    
    func writeDataToNFC() {
        NFCUtility.performAction(.writeData(writePayloadContent)) { _ in
            self.writePayloadContent = ""
        }
    }
    
}
