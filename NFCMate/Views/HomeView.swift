//
//  HomeView.swift
//  NFCMate
//
//  Created by NAVEEN MADHAN on 1/15/22.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        
        NavigationView {
            
            ZStack {
                VStack(spacing: 15) {
                    
                    NavigationLink(destination: ScanNFCView()) {
                        Text("Scan Tag.")
                            .padding()
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: UIScreen.main.bounds.width - 50)
                            .background(Color.blue)
                            .cornerRadius(30)
                    }
                    
                    NavigationLink(destination: WriteToNFCView()) {
                        Text("Write Tag.")
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
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
