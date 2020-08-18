package com.stucare.cloud_parent.video_lessons

import android.app.ProgressDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.DashBoardBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.stucare.cloud_parent.tests.AdapterSchoolTestsMain
import com.stucare.cloud_parent.tests.OnlineTestsActivity
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

/**
 * Author: Ashish Walia(ashishwalia.me) on 02-11-2017.
 */

class FrgVideoLessons : Fragment() {

    private lateinit var progressBar: ProgressDialog
    lateinit var contentView: DashBoardBinding


    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        contentView = DataBindingUtil.inflate(inflater, R.layout.dash_board, container, false)
        contentView.controller = this@FrgVideoLessons

        progressBar = ProgressDialog(activity)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")
        return contentView.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        getVideoLessons()
    }

    fun refreshContent() {
        contentView.recyclerView.adapter!!.notifyDataSetChanged()
    }

    private fun getVideoLessons() {
        progressBar.show()
        val parentActivity = activity as ActivityVideoLessons
        val call = NetworkClient.create().getVideoLessonSubjects(
            parentActivity.stucareId!!,
            parentActivity.accessToken!!
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
                            contentView.recyclerView.layoutManager = GridLayoutManager(activity, 2)
                            val dashboardAdapter = AdapterDashboardSubjects(activity as ActivityVideoLessons,jsonArray)
                            contentView.recyclerView.adapter = dashboardAdapter

                        }

                    }
                    progressBar.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    activity!!,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }


        })
    }

}
