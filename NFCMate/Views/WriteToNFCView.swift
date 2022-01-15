//
//  WriteToNFCView.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/15/22.
//

import SwiftUI

struct WriteToNFCView: View {
    @State private var urlT: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                TextField("Enter Text", text: $urlT)
                    .padding()
                    .font(.headline)
                    .frame(maxWidth: UIScreen.main.bounds.width - 50)
                    .background(Color.white)
                    .cornerRadius(30)
                
                Button(action: {
                    // writer.scan(writeData: urlT)
                    NFCUtility.performAction(.writeData(urlT)) { _ in
                      self.urlT = ""
                    }
                }) {
                    Text("Write To Tag")
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

struct WriteToNFCView_Previews: PreviewProvider {
    static var previews: some View {
        WriteToNFCView()
    }
}
