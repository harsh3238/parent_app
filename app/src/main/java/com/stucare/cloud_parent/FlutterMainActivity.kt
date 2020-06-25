package com.stucare.cloud_parent

import android.app.ProgressDialog
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.stucare.cloud_parent.classrooms.ActivityClassesTabs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel


class FlutterMainActivity : FlutterActivity() {
    private val METHOD_CHANNEL_NAME = "com.stucare.cloud_parent/flutter_method_channel"
    private lateinit var mProgressDialog: ProgressDialog
    private var mMethodResult: MethodChannel.Result? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mProgressDialog = ProgressDialog(this)
        mProgressDialog.setCancelable(false)
        mProgressDialog.isIndeterminate = true
        mProgressDialog.setMessage("Please wait...")

        MethodChannel(
            flutterEngine?.dartExecutor?.binaryMessenger,
            METHOD_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            mMethodResult = result
            when (call.method) {
                "startLiveClassActivity" -> {
                    startActivity(Intent(this, ActivityClassesTabs::class.java))
                }
            }
        }
    }
}