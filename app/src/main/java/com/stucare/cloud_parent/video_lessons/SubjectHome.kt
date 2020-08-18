package com.stucare.cloud_parent.video_lessons

import android.app.ProgressDialog
import android.graphics.Color
import android.os.Bundle
import android.view.Menu
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.GridLayoutManager
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.SubjectHomeBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

/**
 * Author: Ashish Walia(ashishwalia.me) on 03-11-2017.
 */

class SubjectHome : AppCompatActivity() {

  var schoolId: Int? = null
  var stucareId: Int? = null
  var subjectId: String? = null
  var accessToken: String? = null
  lateinit var contentView: SubjectHomeBinding
  private lateinit var progressBar: ProgressDialog


  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    contentView = DataBindingUtil.setContentView(this, R.layout.subject_home)
    progressBar = ProgressDialog(this)
    progressBar.setCancelable(false)
    progressBar.isIndeterminate = true
    progressBar.setMessage("Please wait...")

    schoolId = intent.getIntExtra("schoolId", -1)
    stucareId = intent.getIntExtra("stucareId", -1)
    accessToken = intent.getStringExtra("sessionToken")
    subjectId = intent.getStringExtra("subjectId")

    contentView.recyclerView.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)

    getTopics()
  }



  fun getTopics() {
    progressBar.show()
    val call = NetworkClient.create().getVideoChapters(
      subjectId!!,
      accessToken!!
    )
    call.enqueue(object : Callback<String> {

      override fun onResponse(call: Call<String>?, response: Response<String>?) {
        response?.let {
          if (response.isSuccessful) {
            val jsonObject = JSONObject(response.body().toString())
            if (jsonObject.has("status") &&
              jsonObject.getString("status") == "success"
            ) {
              val jsonArray = jsonObject.getJSONArray("data")
              contentView.recyclerView.adapter = AdapterSubjectHome(this@SubjectHome, jsonArray)

            }

          }
          progressBar.dismiss()
        }
      }

      override fun onFailure(call: Call<String>?, t: Throwable?) {
        progressBar.dismiss()
        Toast.makeText(
          this@SubjectHome,
          "There has been error, please try again",
          Toast.LENGTH_SHORT
        )
          .show()
      }


    })
  }
}
