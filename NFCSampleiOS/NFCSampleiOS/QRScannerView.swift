//
//  QRScannerView.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerVC {
        let vc = QRScannerVC()
        vc.onResult = completion
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerVC, context: Context) {}
}

class QRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onResult: ((String) -> Void)?
    let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)

        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        session.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let text = obj.stringValue {
            session.stopRunning()
            onResult?(text)
            dismiss(animated: true)
        }
    }
}
