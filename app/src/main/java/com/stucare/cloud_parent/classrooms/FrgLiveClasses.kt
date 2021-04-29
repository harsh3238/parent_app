package com.stucare.cloud_parent.classrooms

import AdapterClassRoom
import android.annotation.SuppressLint
import android.app.ProgressDialog
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.firebase.analytics.FirebaseAnalytics
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ClassRoomMainBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.stucare.cloud_parent.tests.CustomAlertDialog
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import us.zoom.sdk.*


class FrgLiveClasses : Fragment() {

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
            @SuppressLint("InvalidAnalyticsName")
            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                if (response != null && response.isSuccessful) {

                    try {
                        var responseString = response.body();
                        if(responseString == "auth error"){
                            progressDialog.dismiss()
                            val params = Bundle()
                            params.putString("response", ""+response.body())
                            params.putString("type", "auth error")
                            (activity as ActivityClassesTabs).firebaseAnalytics.logEvent("live_class_api", params)
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
                                    startLiveClass(it)
                                }
                        }
                    } catch (e: Exception) {
                        val params = Bundle()
                        params.putString("response", ""+response.body())
                        params.putString("error", ""+e.stackTrace.toString())
                        params.putString("type", "crash")
                        params.putString("message", ""+e.localizedMessage)
                        (activity as ActivityClassesTabs).firebaseAnalytics.logEvent("live_class_api", params)
                        Toast.makeText(activity,
                            "Error: "+e.localizedMessage,
                            Toast.LENGTH_LONG
                        ).show()
                        Toast.makeText(activity, "Error: "+e.localizedMessage, Toast.LENGTH_SHORT).show()
                    }
                }
                progressDialog.dismiss()
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressDialog.dismiss()
            }
        })
    }

    @SuppressLint("InvalidAnalyticsName")
    fun startLiveClass(meetingObject: JSONObject){

        var liveType  = meetingObject.optString("live_type")
        if(liveType==null || liveType==""){
            Toast.makeText(activity, "Unknown Class Type", Toast.LENGTH_LONG
            ).show()
            return
        }

        if (meetingObject.getString("live_type") == "gmeet") {

            var liveLink = meetingObject.getString("live_link");
            if(!liveLink.contains("http")){
                liveLink = "http://"+meetingObject.getString("live_link");
            }


            Log.d("LIVE_CLASS", "GMEET")
            val mapIntent: Intent = Uri.parse(liveLink).let { liveClass ->
                Intent(Intent.ACTION_VIEW, liveClass)
            }
            try {
                startActivity(mapIntent);
            } catch (e: ActivityNotFoundException) {
                Toast.makeText(
                    activity,
                    "No app found to start GMeet live class",
                    Toast.LENGTH_LONG
                ).show()
            }


        } else if (meetingObject.getString("live_type") == "zoom_link") {
            Log.d("LIVE_CLASS", "ZOOM LINK")
            var liveLink = meetingObject.getString("live_link");
            val mapIntent: Intent = Uri.parse(liveLink).let { liveClass ->
                Intent(Intent.ACTION_VIEW, liveClass)
            }
            try {
                startActivity(mapIntent);
            } catch (e: ActivityNotFoundException) {
                Toast.makeText(
                    activity,
                    "Please install Zoom application",
                    Toast.LENGTH_LONG
                ).show()
            }

        } else if (meetingObject.getString("live_type") == "youtube") {
            Log.d("LIVE_CLASS", "YOUTUBE")

        } else if (meetingObject.getString("live_type") == "zoom") {
            Log.d("LIVE_CLASS", "ZOOM")
            try {
                val meetingService: MeetingService = ZoomSDK.getInstance().meetingService
                if (meetingService != null) {
                    val opts = JoinMeetingOptions()

                    opts.no_driving_mode = true
                    opts.no_invite = true
                    opts.no_meeting_end_message = false
                    opts.no_titlebar = false
                    opts.no_bottom_toolbar = false
                    opts.no_dial_in_via_phone = true
                    opts.no_dial_out_to_phone = true
                    opts.no_disconnect_audio = true
                    opts.no_share = true
                    opts.invite_options =
                        InviteOptions.INVITE_VIA_EMAIL + InviteOptions.INVITE_VIA_SMS
                    opts.no_audio = false
                    opts.no_video = true
                    opts.meeting_views_options =
                        MeetingViewsOptions.NO_BUTTON_SHARE + MeetingViewsOptions.NO_TEXT_MEETING_ID + MeetingViewsOptions.NO_TEXT_PASSWORD
                    opts.no_meeting_error_message = true

                    val params = JoinMeetingParams()
                    params.displayName = (activity as ActivityClassesTabs).studentName
                    params.meetingNo = meetingObject.getString("live_link")
                    params.password = meetingObject.getString("live_password")

                    val response = meetingService.joinMeetingWithParams(activity, params, opts)
                    markAttendance(meetingObject)
                }
            }catch (e: Exception){
                val params = Bundle()
                params.putString("json", ""+meetingObject.toString())
                params.putString("error", ""+e.stackTrace.toString())
                params.putString("message", ""+e.localizedMessage)
                (activity as ActivityClassesTabs).firebaseAnalytics.logEvent("zoom class", params)
                Toast.makeText(activity,
                    "Error: "+e.localizedMessage,
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }
    private fun markAttendance(meeting: JSONObject) {
        Log.d("LIVECLASS", meeting.toString())
        val parentActivity = activity as ActivityClassesTabs
        val call = NetworkClient.create().markLiveClassAttendance(
            meeting.getString("section_id"),
            meeting.getString("subject_id"),
            meeting.getString("id"),
            parentActivity.stucareId.toString(),
            meeting.getString("class_id"),
            parentActivity.accessToken!!)
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
        d.setMessage("There is issue with authentication token, please login again.")
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