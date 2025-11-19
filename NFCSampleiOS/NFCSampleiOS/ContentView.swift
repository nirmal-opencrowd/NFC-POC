//
//  ContentView.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                
                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Follow these simple steps to scan a QR code and write the data to an NFC tag.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {

                    HStack(alignment: .top, spacing: 16) {
                        //Circle().frame(width: 10)
                        Text("Step-1:- Scan the QR code to extract the data.")
                    }

                    HStack(alignment: .top, spacing: 16) {
                        //Circle().frame(width: 10)
                        Text("Step-2:- Review or edit the extracted data in the text field.")
                    }

                    HStack(alignment: .top, spacing: 16) {
                        //Circle().frame(width: 10)
                        Text("Step-3:- Tap “Write to NFC Tag” and hold your iPhone near the NFC tag.")
                    }
                }
                .padding(.horizontal)

                Spacer()

                NavigationLink(destination: QRAndNFCView()) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
