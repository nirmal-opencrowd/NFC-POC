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
            
            
            ZStack(alignment: .topLeading) {

                if viewModel.scannedText.isEmpty {
                    Text("Scanned data appears here…")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.scannedText)
                    .padding(12)
                    .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.endEditing()
                                }
                            }
                        }
            }
            .frame(height: 100)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 20)


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
            

            // Write NFC Button
            Button(action: { viewModel.startNFCWriting() }) {
                HStack {
                    Image(systemName: "wave.3.right.circle")
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




extension UITextView {
    open override var backgroundColor: UIColor? {
        get { .clear }
        set { }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
