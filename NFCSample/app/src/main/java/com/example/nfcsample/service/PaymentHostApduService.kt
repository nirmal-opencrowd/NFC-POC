package com.example.nfcsample.service

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import org.json.JSONObject

class PaymentHostApduService : HostApduService() {

    companion object {
        private const val TAG = "MyHceService"
        private const val SELECT_APDU = "00A4040007F039414814810000"
        private const val STATUS_SUCCESS = "9000"
        private const val STATUS_FAILED = "6F00"

        // Data to send to consumer
        var merchantData: MerchantData? = null
    }

    data class MerchantData(
        val uuid: String,
    )

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            return hexStringToByteArray(STATUS_FAILED)
        }

        val hexCommandApdu = byteArrayToHexString(commandApdu)
        Log.d(TAG, "Received APDU: $hexCommandApdu")

        return when {
            hexCommandApdu.startsWith(SELECT_APDU.substring(0, 10)) -> {
                // SELECT command received
                Log.d(TAG, "SELECT command received")
                hexStringToByteArray(STATUS_SUCCESS)
            }
            hexCommandApdu.startsWith("00B0") -> {
                // READ command - send merchant data
                sendMerchantData()
            }
            else -> {
                Log.d(TAG, "Unknown command")
                hexStringToByteArray(STATUS_FAILED)
            }
        }
    }

    private fun sendMerchantData(): ByteArray {
        val data = merchantData ?: return hexStringToByteArray(STATUS_FAILED)

        try {
            val json = JSONObject().apply {
                put("uuid", data.uuid)
            }

            val jsonString = json.toString()
            val dataBytes = jsonString.toByteArray(Charsets.UTF_8)

            Log.d(TAG, "Sending data: $jsonString")

            // Append success status
            return dataBytes + hexStringToByteArray(STATUS_SUCCESS)
        } catch (e: Exception) {
            Log.e(TAG, "Error creating response", e)
            return hexStringToByteArray(STATUS_FAILED)
        }
    }

    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "Deactivated: $reason")
    }

    private fun byteArrayToHexString(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02X".format(it) }
    }

    private fun hexStringToByteArray(hex: String): ByteArray {
        val len = hex.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(hex[i], 16) shl 4) +
                    Character.digit(hex[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }
}