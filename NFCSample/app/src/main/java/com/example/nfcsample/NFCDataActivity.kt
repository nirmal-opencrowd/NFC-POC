package com.example.nfcsample

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.nfc.FormatException
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.TagLostException
import android.nfc.cardemulation.CardEmulation
import android.nfc.tech.Ndef
import android.os.Bundle
import android.util.Log
import android.view.MotionEvent
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.activity.ComponentActivity
import com.example.nfcsample.service.PaymentHostApduService
import com.google.zxing.integration.android.IntentIntegrator
import com.google.zxing.integration.android.IntentResult
import java.io.IOException
import java.nio.charset.Charset

class NFCDataActivity : ComponentActivity() {
    private var nfcAdapter: NfcAdapter? = null
    private var pendingURL: String? = null
    private var pendingIntent: PendingIntent? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_nfc_data)

        val nfcDataEditText = findViewById<EditText>(R.id.nfcDataEditText)
        val writeNFCBtn = findViewById<Button>(R.id.writeDataToNFCTagBtn)
        val sendNFCBtn = findViewById<Button>(R.id.sendDataViaNFCBtn)

        nfcDataEditText.onRightDrawableClicked {
            IntentIntegrator(this)
                .setDesiredBarcodeFormats(IntentIntegrator.QR_CODE)
                .setPrompt("Scan a QR Code")
                .setBeepEnabled(true)
                .setOrientationLocked(true)
                .initiateScan()
        }

        writeNFCBtn.setOnClickListener {
            val dataToSendUrl = getNfcDataFromInput()
            if (dataToSendUrl.isNotBlank()) {
                Log.d("Payment URL", dataToSendUrl)
                onNewURLCreated(dataToSendUrl)
                Toast.makeText(this, "Please hold the phone near the NFC Tag", Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, "Please enter or scan data first", Toast.LENGTH_LONG).show()
            }
        }

        sendNFCBtn.setOnClickListener {
            val dataToSendUrl = getNfcDataFromInput()
            if (dataToSendUrl.isNotBlank()) {
                Log.d("Payment URL", dataToSendUrl)
                prepareDataForTransfer(dataToSendUrl)
            } else {
                Toast.makeText(this, "Please enter or scan data first", Toast.LENGTH_LONG).show()
            }
        }

        pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_MUTABLE
        )

        initNFC()
    }

    private fun initNFC() {
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        if (nfcAdapter == null) {
            Toast.makeText(this, "NFC not supported in this device.", Toast.LENGTH_LONG).show()
            return
        }

        if (!nfcAdapter!!.isEnabled) {
            Log.e("onCreate", "Please enable NFC from Settings.")
            Toast.makeText(this, "Please enable NFC from Settings.", Toast.LENGTH_LONG).show()
        }

        // Check if HCE is supported
        val cardEmulation = CardEmulation.getInstance(nfcAdapter)
        if (cardEmulation != null) {
            Log.d("cardEmulation", "Ready to send data via NFC")
        } else {
            Log.d("cardEmulation", "HCE not supported on this device")
        }
    }

    private fun getNfcDataFromInput(): String {
        val nfcDataEditText = findViewById<EditText>(R.id.nfcDataEditText)
        return nfcDataEditText.text.toString().trim()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        if (NfcAdapter.ACTION_TAG_DISCOVERED == intent.action || NfcAdapter.ACTION_NDEF_DISCOVERED == intent.action) {
            val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)

            if (tag != null && pendingURL != null) {
                writeUrlToTag(tag, pendingURL!!)
            }
        }
    }

    private fun writeUrlToTag(tag: Tag, url: String) {
        try {
            // Create NDEF record with URL
            val ndefRecord = createUrlRecord(url)
            val ndefMessage = NdefMessage(arrayOf(ndefRecord))

            // Write to tag
            val ndef = Ndef.get(tag)
            ndef?.let {
                it.connect()

                if (!it.isWritable) {
                    Log.d("writeUrlToTag", "Tag is not writable")
                    Toast.makeText(this, "Tag is not writable", Toast.LENGTH_LONG).show()
                    return
                }

                if (ndefMessage.toByteArray().size > it.maxSize) {
                    Log.d("writeUrlToTag", "URL is too large for this tag")
                    Toast.makeText(this, "URL is too large for this tag", Toast.LENGTH_LONG).show()
                    return
                }

                it.writeNdefMessage(ndefMessage)
                it.close()

                Log.d("writeUrlToTag", "URL written successfully!")
                Toast.makeText(this, "URL written successfully!", Toast.LENGTH_LONG).show()
            } ?: run {
                Log.e("Error writeUrlToTag", "Tag does not support NDEF")
                Toast.makeText(this, "Tag does not support NDEF", Toast.LENGTH_LONG).show()
            }

        } catch (e: TagLostException) {
            Log.e("Error writeUrlToTag Tag Lost", e.message ?: e.toString())
            Toast.makeText(this, "Tag lost during write, please try again", Toast.LENGTH_LONG)
                .show()
        } catch (e: FormatException) {
            Log.e("Error writeUrlToTag Format", e.message ?: e.toString())
            Toast.makeText(this, "Tag format not supported or corrupted", Toast.LENGTH_LONG).show()
        } catch (e: IOException) {
            Log.e("Error writeUrlToTag IO", e.message ?: e.toString())
            Toast.makeText(this, "I/O error during write: ${e.message}", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Log.e("Error writeUrlToTag Exc", e.message ?: e.toString())
            Toast.makeText(this, "Write failed: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun createUrlRecord(url: String): NdefRecord {
        // Determine URL prefix
        val urlBytes: ByteArray
        val prefix: Byte

        when {
            url.startsWith("http://www.") -> {
                prefix = 0x01
                urlBytes = url.substring(11).toByteArray(Charset.forName("US-ASCII"))
            }

            url.startsWith("https://www.") -> {
                prefix = 0x02
                urlBytes = url.substring(12).toByteArray(Charset.forName("US-ASCII"))
            }

            url.startsWith("http://") -> {
                prefix = 0x03
                urlBytes = url.substring(7).toByteArray(Charset.forName("US-ASCII"))
            }

            url.startsWith("https://") -> {
                prefix = 0x04
                urlBytes = url.substring(8).toByteArray(Charset.forName("US-ASCII"))
            }

            else -> {
                prefix = 0x00
                urlBytes = url.toByteArray(Charset.forName("US-ASCII"))
            }
        }

        val payload = ByteArray(urlBytes.size + 1)
        payload[0] = prefix
        System.arraycopy(urlBytes, 0, payload, 1, urlBytes.size)

        return NdefRecord(
            NdefRecord.TNF_WELL_KNOWN,
            NdefRecord.RTD_URI,
            ByteArray(0),
            payload
        )
    }

    fun onNewURLCreated(url: String) {
        pendingURL = url
    }

    private fun prepareDataForTransfer(dataToSendUrl: String) {
        // Prepare merchant data
        val data = PaymentHostApduService.MerchantData(
            uuid = dataToSendUrl
        )
        PaymentHostApduService.merchantData = data

        Log.d("data", "Data ready! Bring consumer phone close to transfer:\n\n" + "uuid: ${data.uuid}\n")
        Toast.makeText(applicationContext, "Hold consumer phone near this device", Toast.LENGTH_LONG).show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val result: IntentResult =
            IntentIntegrator.parseActivityResult(requestCode, resultCode, data)
        if (result.contents != null) {
            val nfcDataEditText = findViewById<EditText>(R.id.nfcDataEditText)
            nfcDataEditText.setText(result.contents)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onResume() {
        super.onResume()

        val intentFilters = arrayOf(
            IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED),
            IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED)
        )

        nfcAdapter?.enableForegroundDispatch(
            this,
            pendingIntent,
            intentFilters,
            null
        )
    }

    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(this)
    }

    @SuppressLint("ClickableViewAccessibility")
    fun EditText.onRightDrawableClicked(onClicked: (view: EditText) -> Unit) {
        this.setOnTouchListener { v, event ->
            var hasConsumed = false
            if (v is EditText) {
                if (event.x >= v.width - v.totalPaddingRight) {
                    if (event.action == MotionEvent.ACTION_UP) {
                        onClicked(this)
                    }
                    hasConsumed = true
                }
            }
            hasConsumed
        }
    }
}