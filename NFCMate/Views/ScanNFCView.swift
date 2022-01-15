//
//  ScanNFCView.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/15/22.
//

import SwiftUI
import CoreNFC

struct ScanNFCView: View {
    @State private var writer: String?
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 15) {
                Text("\(writer == nil ? "NO DATA" : writer!)")
                    .padding()
                    .font(.headline)
                    .frame(maxWidth: UIScreen.main.bounds.width - 50)
                    .background(Color.white)
                    .cornerRadius(30)
                
                Button(action: {
                    NFCUtility.performAction(.readData) { data in
                        self.handleScanData(data)
                    }
                }) {
                    Text("Scan Tag.")
                        .padding()
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: UIScreen.main.bounds.width - 50)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
            }
        }.background(
            GradientBG()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea()
        )
    }
}

struct ScanNFCView_Previews: PreviewProvider {
    static var previews: some View {
        ScanNFCView()
    }
}

extension ScanNFCView {
    
    private func handleScanData(_ completion: Result<NFCNDEFMessage?, Error>) {
        
        let message: NFCNDEFMessage? = try? completion.get()
        
        guard let message = message, let payload = message.records.first else {
            print("NO PAYLOAD")
            return
        }
        switch payload.typeNameFormat {
        case .nfcWellKnown:
            if let type = String(data: payload.type, encoding: .utf8) {
                if let url = payload.wellKnownTypeURIPayload() {
                    self.writer = "\(payload.typeNameFormat.description): \(type), \(url.absoluteString)"
                } else {
                    self.writer = "\(payload.typeNameFormat.description): \(type)"
                }
            }
        case .absoluteURI:
            if let text = String(data: payload.payload, encoding: .utf8) {
                self.writer = text
            }
        case .media:
            if let type = String(data: payload.type, encoding: .utf8) {
                self.writer = "\(payload.typeNameFormat.description): " + type
            }
        case .nfcExternal, .empty, .unknown, .unchanged:
            fallthrough
        @unknown default:
            self.writer = payload.typeNameFormat.description
        }
    }
}
