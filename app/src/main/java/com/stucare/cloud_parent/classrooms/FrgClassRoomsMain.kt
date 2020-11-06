package com.stucare.cloud_parent.classrooms

import AdapterClassRoom
import android.app.ProgressDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ClassRoomMainBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.stucare.cloud_parent.tests.CustomAlertDialog
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response


class FrgClassRoomsMain : Fragment() {
    private lateinit var progressDialog: ProgressDialog

    lateinit var contentView: ClassRoomMainBinding


    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        contentView = DataBindingUtil.inflate<ClassRoomMainBinding>(
            inflater,
            R.layout.class_room_main, container, false
        )
        return contentView.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        progressDialog = ProgressDialog(activity)
        progressDialog.setCancelable(false)
        progressDialog.isIndeterminate = true
        progressDialog.setMessage("Please wait...")

        contentView.recyclerView.layoutManager = LinearLayoutManager(activity)

        getLiveVideos()
        super.onViewCreated(view, savedInstanceState)
    }

    private fun getLiveVideos() {
        progressDialog.show()
        val parentActivity = activity as ActivityClassesTabs
        val call = NetworkClient.create().getLiveClasses(
            parentActivity.schoolId!!,
            parentActivity.stucareId!!,
            parentActivity.accessToken!!
        )
        call.enqueue(object : Callback<String> {
            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                if (response != null && response.isSuccessful) {
                    var responseString = response.body();
                    if(responseString == "auth error"){
                        progressDialog.dismiss()
                        showAuthDialog()
                        return
                    }
                    val responseObject = JSONObject(response.body().toString().trim())
                    if (responseObject.has("status") && responseObject.getString("status") == "success") {
                        val dataObject = responseObject.getJSONArray("data")
                        if(dataObject.length()==0){
                            Toast.makeText(
                                activity,
                                "No Live Class Available",
                                Toast.LENGTH_SHORT
                            ).show()
                        }
                        contentView.recyclerView.adapter =
                            AdapterClassRoom(activity as ActivityClassesTabs, dataObject) {
                                markAttendance(it)
                            }
                    }
                }
                progressDialog.dismiss()
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressDialog.dismiss()
            }
        })
    }

    fun markAttendance(classId: String) {
        val parentActivity = activity as ActivityClassesTabs
        val call = NetworkClient.create().markLiveClassAttendance(parentActivity.stucareId.toString(), classId, parentActivity.accessToken!!)
        call.enqueue(object : Callback<String> {
          override fun onResponse(call: Call<String>?, response: Response<String>?) {
          }

          override fun onFailure(call: Call<String>?, t: Throwable?) {
          }
        })
    }

    fun showAuthDialog() {
        val d = CustomAlertDialog(requireContext(), R.style.PurpleTheme)
        d.setCancelable(false)
        d.setTitle("Auth Failure... !")
        d.setMessage("There is issue with authentication token, please try again.")
        d.positiveButton.text = "Ok"
        d.negativeButton.text = "Close"

        d.positiveButton.setOnClickListener {
            d.dismiss()
            this?.activity?.finish();
        }

        d.negativeButton.setOnClickListener {
            d.dismiss()
            this?.activity?.finish();
        }
        d.show()
    }

}