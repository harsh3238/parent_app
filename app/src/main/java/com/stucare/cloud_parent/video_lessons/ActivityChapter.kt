package com.stucare.cloud_parent.video_lessons

import android.app.ProgressDialog
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.TopicHomeBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response


class ActivityChapter : AppCompatActivity() {

    lateinit var contentView: TopicHomeBinding
    private lateinit var progressBar: ProgressDialog
    var accessToken: String? = null
    var chapterId: String? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Videos"
        contentView = DataBindingUtil.setContentView(this, R.layout.topic_home)
        progressBar = ProgressDialog(this)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")

        accessToken = intent.getStringExtra("sessionToken")
        chapterId = intent.getStringExtra("chapterId")

        contentView.recyclerView.layoutManager =
            androidx.recyclerview.widget.LinearLayoutManager(this)

        getTopicDetails()

    }

    fun showProgressbar() {
        progressBar.show()
    }

    fun hideProgressbar() {
        progressBar.dismiss()
    }

    private fun getTopicDetails() {
        showProgressbar()
        val call = NetworkClient.create().getVideoLessons(
            chapterId!!,
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
                            contentView.recyclerView.adapter =
                                AdapterChapter(this@ActivityChapter, jsonArray)

                        }

                    }
                    progressBar.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    this@ActivityChapter,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }

        })

    }

}
