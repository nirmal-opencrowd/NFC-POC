//
//  Untitled.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import AVFoundation
import Combine

class CameraPermissionManager: ObservableObject {
    @Published var isCameraAllowed: Bool = false
    @Published var isCameraDenied: Bool = false

    init() {
        checkPermission()
    }

    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isCameraAllowed = true
            isCameraDenied = false

        case .denied, .restricted:
            isCameraAllowed = false
            isCameraDenied = true

        case .notDetermined:
            requestPermission()

        @unknown default:
            isCameraAllowed = false
            isCameraDenied = true
        }
    }

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.isCameraAllowed = true
                    self.isCameraDenied = false
                } else {
                    self.isCameraAllowed = false
                    self.isCameraDenied = true
                }
            }
        }
    }
}
