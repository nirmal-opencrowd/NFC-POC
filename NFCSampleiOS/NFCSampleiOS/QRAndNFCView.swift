//
//  QRAndNFCView.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import SwiftUI
import CoreNFC


struct QRAndNFCView: View {
    @StateObject private var cameraPermission = CameraPermissionManager()
    @StateObject private var viewModel = QRAndNFCViewModel()
    @State private var showScanner = false

    var body: some View {
        VStack(spacing: 20) {

            Text("Scan & Write NFC")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            TextField("Scanned data appears here...",
                      text: $viewModel.scannedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Scan QR Button
            
            // MARK: - QR Scan Button
            Button(action: {
                if cameraPermission.isCameraAllowed {
                    showScanner = true
                } else {
                    cameraPermission.checkPermission()
                }
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan QR Code")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(cameraPermission.isCameraDenied ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(cameraPermission.isCameraDenied)

            // MARK: - Camera Denied Message
            if cameraPermission.isCameraDenied {
                Text("Camera access is denied. Enable it in Settings > Privacy > Camera.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            
            
//            Button(action: { showScanner = true }) {
//                HStack {
//                    Image(systemName: "qrcode.viewfinder")
//                    Text("Scan QR Code")
//                }
//                .foregroundColor(.white)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.blue)
//                .cornerRadius(12)
//            }
//            .padding(.horizontal)

            // Write NFC Button
            Button(action: { viewModel.startNFCWriting() }) {
                HStack {
                    Image(systemName: "nfc")
                    Text("Write to NFC Tag")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    viewModel.scannedText.isEmpty ? Color.gray : Color.green
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(viewModel.scannedText.isEmpty)

            Spacer()

        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { result in
                viewModel.scannedText = result
                showScanner = false
            }
        }
        .alert(viewModel.statusMessage, isPresented: $viewModel.showStatus) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            cameraPermission.checkPermission()
        }

    }
}

#Preview {
    QRAndNFCView()
}
