//
//  QRScannerView.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import SwiftUI
import AVFoundation
import Combine


struct QRScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    var onResult: (String) -> Void

    @StateObject private var cameraModel = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session)
                .onAppear {
                    cameraModel.checkPermissions()
                }

            // Dark mask + transparent center
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .mask(
                    ScannerMask()
                        .fill(style: FillStyle(eoFill: true))
                )
                .allowsHitTesting(false)

            // Red scanning line animation
            ScanningLine()
                .frame(width: 250, height: 250)
                .allowsHitTesting(false)

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onChange(of: cameraModel.scannedCode) { code in
            if let code = code {
                onResult(code)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    @Published var session = AVCaptureSession()

    private let queue = DispatchQueue(label: "camera.queue")

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupCamera() }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        queue.async {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device)
            else { return }

            let output = AVCaptureMetadataOutput()

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
            }

            self.session.startRunning()
        }
    }

    // MARK: - QR Callback
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let value = object.stringValue {
            scannedCode = value
            session.stopRunning()
        }
    }
}




struct ScannerOverlay: View {
    @State private var lineOffset: CGFloat = -150

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Transparent hole mask
                Color.black.opacity(0.55)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: geo.size.width - 80,
                                           height: geo.size.width - 80)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()

                // Animated scanning line
                Rectangle()
                    .fill(Color.red)
                    .frame(width: geo.size.width - 120, height: 3)
                    .offset(y: lineOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            lineOffset = (geo.size.width - 80) / 2
                        }
                    }
            }
        }
    }
}


struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ScannerMask: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let scanRect = CGRect(
            x: rect.midX - 125,
            y: rect.midY - 125,
            width: 250,
            height: 250
        )
        path.addRect(scanRect)
        return path
    }
}

struct ScanningLine: View {
    @State private var offset: CGFloat = -120

    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(height: 3)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    offset = 120
                }
            }
    }
}
