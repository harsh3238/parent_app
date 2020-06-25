package com.stucare.cloud_parent.tests

import android.app.ProgressDialog
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.classrooms.ActivityClassesTabs
import com.stucare.cloud_parent.databinding.ActivitySchoolTestsBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response


class FrgSchoolTests : Fragment() {

    private lateinit var progressBar: ProgressDialog
    lateinit var contentView: ActivitySchoolTestsBinding

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        contentView =
            DataBindingUtil.inflate(inflater, R.layout.activity_school_tests, container, false)
        contentView.recyclerView.layoutManager = LinearLayoutManager(activity)

        progressBar = ProgressDialog(activity)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")
        return contentView.root
    }

    override fun onResume() {
        super.onResume()
        val autoTime =
            Settings.Global.getInt(activity?.contentResolver, Settings.Global.AUTO_TIME, 0)
        val autoTimeZone =
            Settings.Global.getInt(activity?.contentResolver, Settings.Global.AUTO_TIME_ZONE, 0)
        if (autoTime == 0 || autoTimeZone == 0) {
            val alertDialog = AlertDialog.Builder(activity!!, R.style.blackControls)
            alertDialog.setTitle("Automatic Time Not Enabled")
            alertDialog.setMessage("Our app uses your phone's date and time to authenticate you and for other security measures, In order to use our app, you must enable the automatic date and time settings.")
            alertDialog.setPositiveButton("Okay") { dialog, which ->
                startActivity(Intent(Settings.ACTION_DATE_SETTINGS))
                dialog.dismiss()
            }
            alertDialog.setCancelable(false)
            alertDialog.show()

        } else {
            getSchoolTests()
        }
    }

    private fun getSchoolTests() {
        progressBar.show()
        val parentActivity = activity as OnlineTestsActivity
        val call = NetworkClient.create().getSchoolTests(
            parentActivity.schoolId!!,
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
                            contentView.recyclerView.adapter = AdapterSchoolTestsMain(
                                activity!!,
                                jsonArray,
                                "(activity!!.application as MyApplication).usersData.id"
                            )
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