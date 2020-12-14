package com.stucare.cloud_parent.video_lessons

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.retrofit.NetworkClient

class ActivityVideoLessons : AppCompatActivity() {
    var schoolId: Int? = null
    var stucareId: Int? = null
    var accessToken: String? = null
    var schoolUrl: String? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Video Lessons"
        schoolId = intent.getIntExtra("schoolId", -1)
        stucareId = intent.getIntExtra("stucareId", -1)
        accessToken = intent.getStringExtra("sessionToken")
        schoolUrl = intent.getStringExtra("baseUrl")
        NetworkClient.baseUrl = schoolUrl!!

        setContentView(R.layout.activity_video_lessons)

    }
}