//
//  NFCWriter.swift
//  NFCSampleiOS
//
//  Created by Nirmal Patidar on 19/11/25.
//

import Foundation
import CoreNFC

@objcMembers
final class NFCWriterDelegate: NSObject, NFCNDEFReaderSessionDelegate {

    // MARK: - Callbacks
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?

    private let message: NFCNDEFMessage
    private let urlString: String

    init(urlString: String) {
        self.urlString = urlString
        if let url = URL(string: urlString),
           let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) {
            self.message = NFCNDEFMessage(records: [urlPayload])
        } else {
            let text = "Invalid URL"
            if let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale(identifier: "en")) {
                self.message = NFCNDEFMessage(records: [payload])
            } else {
                self.message = NFCNDEFMessage(records: [])
            }
        }
        super.init()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session active, ready to write…")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        onError?("Session ended: \(error.localizedDescription)")
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {

        guard tags.count == 1 else {
            let message = "More than one tag detected. Please present one tag."
            session.alertMessage = message
            onError?(message)
            session.restartPolling()
            return
        }

        let tag = tags.first!

        func logError(_ messageStr: String, _ error: Error? = nil) {
            if let error = error {
                onError?("\(messageStr): \(error.localizedDescription)")
                session.invalidate(errorMessage: "\(messageStr): \(error.localizedDescription)")
            } else {
                onError?(messageStr)
                session.invalidate(errorMessage: messageStr)
            }
        }

        func connectAndWrite(retry: Bool = true) {
            session.connect(to: tag) { connectError in
                if let connectError = connectError {
                    if retry {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                            connectAndWrite(retry: false)
                        }
                        return
                    }
                    logError("Connection failed", connectError)
                    return
                }

                tag.queryNDEFStatus { status, capacity, queryError in
                    if let queryError = queryError {
                        logError("Failed reading tag status", queryError)
                        return
                    }

                    switch status {
                    case .notSupported:
                        logError("Tag does not support NDEF")
                    case .readOnly:
                        logError("Tag is read-only")
                    case .readWrite:
//                        tag.writeNDEF(self.message) { writeError in
//                            if let writeError = writeError {
//                                logError("Write failed", writeError)
//                                return
//                            }
//                            session.alertMessage = "✅ Successfully written!"
//                            session.invalidate()
//                            self.onSuccess?()
//                        }
                        
                        //self.onStatusUpdate?("Tag writable. Preparing to overwrite...")
                        self.overwriteAndWrite(tag, session: session)

                        
                    @unknown default:
                        logError("Unknown tag status")
                    }
                }
            }
        }

        connectAndWrite()
    }

    private func overwriteAndWrite(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {

            // Step 2: Create empty NDEF to erase the tag
            let emptyMessage = NFCNDEFMessage(records: [])
            tag.writeNDEF(emptyMessage) { error in
                if let error = error {
                    self.onError?("Erase failed: \(error.localizedDescription)")
                    session.invalidate()
                    return
                }

                // Step 3: Write new NDEF message
                let payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: self.urlString)!
                let message = NFCNDEFMessage(records: [payload])

                tag.writeNDEF(message) { error in
                    if let error = error {
                        self.onError?("Write failed: \(error.localizedDescription)")
                        session.invalidate()
                    } else {
                        self.onSuccess?()
                        session.alertMessage = "✅ Successfully written!"
                        session.invalidate()
                        self.onSuccess?()
                    }
                }
            }
        }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}

}

