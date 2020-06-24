package com.stucare.cloud_parent

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.os.Handler
import io.flutter.embedding.android.FlutterActivity
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        Handler().postDelayed({
            startActivity(
                FlutterActivity.createDefaultIntent(this)
            )
            finish()
        }, 2000)
    }
}