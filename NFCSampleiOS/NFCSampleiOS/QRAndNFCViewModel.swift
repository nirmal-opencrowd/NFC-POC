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
                self?.scannedText = ""
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


