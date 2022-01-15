//
//  NFCUtility.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/15/22.
//


import Foundation
import CoreNFC
import UIKit

typealias NFCReadingCompletion = (Result<NFCNDEFMessage?, Error>) -> Void
typealias dataReadingCompletion = (Result<String, Error>) -> Void
 
enum NFCError: LocalizedError {
    case unavailable
    case invalidated(message: String)
    case invalidPayloadSize
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "NFC Reader Not Available"
        case let .invalidated(message):
            return message
        case .invalidPayloadSize:
            return "NDEF payload size exceeds the tag limit"
        }
    }
}

class NFCUtility: NSObject {
    
    enum NFCAction {
        case readData
        case writeData(_ date: String)
        case addVisitor(visitorName: String)
        
        var alertMessage: String {
            switch self {
            case .readData:
                return "Place tag near iPhone to read the data."
            case .writeData(let data):
                return "Place tag near iPhone to setup \(data)"
            case .addVisitor(let visitorName):
                return "Place tag near iPhone to add \(visitorName)"
            }
        }
    }
    
    private static let shared = NFCUtility()
    private var action: NFCAction = .readData
    
    private var session: NFCNDEFReaderSession?
    private var completion: NFCReadingCompletion?
    
    static func performAction(
        _ action: NFCAction,
        completion: NFCReadingCompletion? = nil
    ) {
        
        guard NFCNDEFReaderSession.readingAvailable else {
            completion?(.failure(NFCError.unavailable))
            print("NFC is not available on this device")
            return
        }
        
        shared.action = action
        shared.completion = completion
        
        shared.session = NFCNDEFReaderSession(
            delegate: shared.self,
            queue: nil,
            invalidateAfterFirstRead: false)
        
        shared.session?.alertMessage = action.alertMessage
        shared.session?.begin()
    }
}

// MARK: - NFC NDEF Reader Session Delegate
extension NFCUtility: NFCNDEFReaderSessionDelegate {
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {}
    
    private func handleError(_ error: Error) {
        session?.alertMessage = error.localizedDescription
        session?.invalidate()
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
        if
            let error = error as? NFCReaderError,
            error.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
                error.code != .readerSessionInvalidationErrorUserCanceled {
            completion?(.failure(NFCError.invalidated(message: error.localizedDescription)))
        }
        
        self.session = nil
        completion = nil
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetect tags: [NFCNDEFTag]
    ) {
        guard
            let tag = tags.first,
            tags.count == 1
        else {
            session.alertMessage = "There are too many tags present. Remove all and then try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                session.restartPolling()
            }
            return
        }
        

        session.connect(to: tag) { error in
            if let error = error {
                self.handleError(error)
                return
            }
            
   
            tag.queryNDEFStatus { status, _, error in
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                
                switch (status, self.action) {
                case (.notSupported, _):
                    session.alertMessage = "Unsupported tag."
                    session.invalidate()
                case (.readOnly, _):
                    session.alertMessage = "Unable to write to tag."
                    session.invalidate()
                case (.readWrite, .writeData(let data)):
                    self.writeData(data, tag: tag)
                    
                case (.readWrite, .readData):
                    self.read(tag: tag)
                    
                case (.readWrite, .addVisitor(let visitorName)):
                    // self.addVisitor(Visitor(name: visitorName), tag: tag)
                    print("VISITOR\(visitorName)")
                default:
                    return
                }
            }
        }
    }
}

// MARK: - Utilities
extension NFCUtility {
    func readData(from tag: NFCNDEFTag) {
        
        tag.readNDEF { message, error in
            if let error = error {
                self.handleError(error)
                return
            }
            
            guard
                let message = message
            else {
                self.session?.alertMessage = "Could not read tag data."
                self.session?.invalidate()
                return
            }
            print(message)
            print(message.length, message.records[0].typeNameFormat.description, message.records[0])
            self.completion?(.success(message))
            self.session?.alertMessage = "Read tag."
            self.session?.invalidate()
        }
    }
    
    private func read(
        tag: NFCNDEFTag,
        alertMessage: String = "Tag Read",
        readCompletion: NFCReadingCompletion? = nil
    ) {
        tag.readNDEF { message, error in
            if let error = error {
                self.handleError(error)
                return
            }
            
            
            if let readCompletion = readCompletion,
               let message = message {
                readCompletion(.success(message))
            } else if let message = message {
                      // let record = message.records.first {
                
                self.completion?(.success(message))
                self.session?.alertMessage = alertMessage
                self.session?.invalidate()
                
            }
        }
    }
    
    private func writeData(_ data: String, tag: NFCNDEFTag) {
      read(tag: tag) { _ in
          self.write(data, tag: tag)
      }
    }
    
    private func write(
        _ data: String,
        tag: NFCNDEFTag
    ) {
        session?.connect(to: tag, completionHandler: {(error: Error?) in
            if let error = error {
                self.session?.alertMessage = "Unable To Connect to Tag \(error)"
                self.session?.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: {(ndefstatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    self.session?.alertMessage = "Unable To Connect to Tag"
                    self.session?.invalidate()
                    return
                }
                
                switch ndefstatus {
                case .notSupported:
                    self.session?.alertMessage = "Unable To Connect to Tag"
                    self.session?.invalidate()
                    
                case .readWrite:
                    tag.writeNDEF(.init(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: "\(data)")!]),
                                  completionHandler: { (error: Error?) in
                        if let error = error {
                            self.session?.alertMessage = "Write Failed \(error)"
                        } else {
                            self.session?.alertMessage = "Success"
                        }
                        self.session?.invalidate()
                    })
                    
                case .readOnly:
                    self.session?.alertMessage = "Unable To Connect to Tag"
                    self.session?.invalidate()
                    
                @unknown default:
                    self.session?.alertMessage = "Unable To Connect to Tag"
                    self.session?.invalidate()
                }
                
            })
        })
    }
    
}


extension NFCTypeNameFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nfcWellKnown: return "NFC Well Known type"
        case .media: return "Media type"
        case .absoluteURI: return "Absolute URI type"
        case .nfcExternal: return "NFC External type"
        case .unknown: return "Unknown type"
        case .unchanged: return "Unchanged type"
        case .empty: return "Empty payload"
        @unknown default: return "Invalid data"
        }
    }
}
