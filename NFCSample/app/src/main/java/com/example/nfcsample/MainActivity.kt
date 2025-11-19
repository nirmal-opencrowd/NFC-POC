package com.example.nfcsample

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.activity.ComponentActivity

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val getStartedButton = findViewById<Button>(R.id.getStartedButton)
        getStartedButton.setOnClickListener {
            val intent = Intent(this, NFCDataActivity::class.java)
            startActivity(intent)
        }
    }

}