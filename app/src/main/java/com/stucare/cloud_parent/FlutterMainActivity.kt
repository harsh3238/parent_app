package com.stucare.cloud_parent

import android.app.ProgressDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import com.stucare.cloud_parent.classrooms.ActivityClassesTabs
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.stucare.cloud_parent.tests.OnlineTestsActivity
import com.stucare.cloud_parent.video_lessons.ActivityVideoLessons
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel


class FlutterMainActivity : FlutterActivity() {
    private val SHARED_PREFERENCES_NAME = "FlutterSharedPreferences"

    private val METHOD_CHANNEL_NAME = "com.stucare.cloud_parent/flutter_method_channel"
    private lateinit var mProgressDialog: ProgressDialog
    private var mMethodResult: MethodChannel.Result? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mProgressDialog = ProgressDialog(this)
        mProgressDialog.setCancelable(false)
        mProgressDialog.isIndeterminate = true
        mProgressDialog.setMessage("Please wait...")

        val preferences = getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
        NetworkClient.baseUrl = preferences.getString("flutter.normal_login_school_url", "https://demo.stucarecloud.in/")!!

       MethodChannel(
            flutterEngine?.dartExecutor?.binaryMessenger,
            METHOD_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            mMethodResult = result
            when (call.method) {
                "startLiveClassActivity" -> {
                    val i = Intent(this, ActivityClassesTabs::class.java)
                    i.putExtra("stucareId", call.argument<Int>("stucareid"))
                    i.putExtra("sessionToken", call.argument<String>("sessionToken"))
                    i.putExtra("schoolId", call.argument<Int>("schoolId"))
                    i.putExtra("studentName", call.argument<String>("studentName"))
                    startActivity(i)
                }
                "startOnlineTestsActivity" -> {
                    val i = Intent(this, OnlineTestsActivity::class.java)
                    i.putExtra("stucareId", call.argument<Int>("stucareid"))
                    i.putExtra("sessionToken", call.argument<String>("sessionToken"))
                    i.putExtra("schoolId", call.argument<Int>("schoolId"))
                    startActivity(i)
                }
                "startVideoLessonsActivity" -> {
                    val i = Intent(this, ActivityVideoLessons::class.java)
                    i.putExtra("stucareId", call.argument<Int>("stucareid"))
                    i.putExtra("sessionToken", call.argument<String>("sessionToken"))
                    i.putExtra("schoolId", call.argument<Int>("schoolId"))
                    startActivity(i)
                }
            }
        }
    }
}