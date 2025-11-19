//
//  Untitled.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import Foundation
import CoreNFC
import Foundation
import CoreNFC
import Combine


class QRAndNFCViewModel: ObservableObject {

    @Published var scannedText = ""
    @Published var statusMessage = ""
    @Published var showStatus = false

    private var session: NFCNDEFReaderSession?
    private var writerDelegate: NFCWriterDelegate?

    func startNFCWriting() {

        writerDelegate = NFCWriterDelegate(urlString: scannedText)

        // callbacks
        writerDelegate?.onSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.statusMessage = "NFC Write Successful!"
                self?.showStatus = true
            }
        }

        writerDelegate?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.statusMessage = error
                self?.showStatus = true
            }
        }

        session = NFCNDEFReaderSession(
            delegate: writerDelegate!,
            queue: nil,
            invalidateAfterFirstRead: false
        )

        session?.alertMessage = "Hold your iPhone near an NFC tag..."
        session?.begin()
    }
}

//
//class QRAndNFCViewModel: NSObject, ObservableObject {
//    @Published var scannedText: String = ""
//    @Published var error: String? = nil
//    private var nfcSession: NFCNDEFReaderSession?
//    private var nfcWriterDelegate: NFCWriterDelegate?
//
//    // MARK: - NFC Writing
//    func startNFCWriting() {
//        let urlToWrite = scannedText
//        print("urlToWrite: \(urlToWrite)")
//        
//        guard NFCNDEFReaderSession.readingAvailable else {
//            error = "❌ NFC not available on this device."
//            return
//        }
//
//        DispatchQueue.main.async {
//            self.nfcSession?.invalidate()
//
//            self.nfcWriterDelegate = NFCWriterDelegate(urlString: urlToWrite)
//            
//            self.nfcSession = NFCNDEFReaderSession(
//                delegate: self.nfcWriterDelegate!,
//                queue: nil,
//                invalidateAfterFirstRead: false
//            )
//
//            self.nfcSession?.alertMessage =
//                "Hold your iPhone near the NFC tag to write."
//            self.nfcSession?.begin()
//
//            print("📡 startNFCWriting session began")
//        }
//    }
//}


