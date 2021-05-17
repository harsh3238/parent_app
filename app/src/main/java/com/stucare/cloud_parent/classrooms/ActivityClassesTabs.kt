package com.stucare.cloud_parent.classrooms

import android.app.ProgressDialog
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentPagerAdapter
import com.google.firebase.analytics.FirebaseAnalytics
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.TicketsTabActivityBinding
import com.stucare.cloud_parent.initsdk.InitAuthSDKCallback
import com.stucare.cloud_parent.initsdk.InitAuthSDKHelper
import com.stucare.cloud_parent.retrofit.NetworkClient
import us.zoom.sdk.ZoomError
import us.zoom.sdk.ZoomSDK


class ActivityClassesTabs : AppCompatActivity(), InitAuthSDKCallback {

    lateinit var firebaseAnalytics: FirebaseAnalytics
    lateinit var contentView: TicketsTabActivityBinding

    lateinit var progressDialog: ProgressDialog
    var schoolId: Int? = null
    var stucareId: Int? = null
    var accessToken: String? = null
    var studentName: String? = null
    var schoolUrl: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "LIVE CLASSES"
        contentView = DataBindingUtil.setContentView(this, R.layout.tickets_tab_activity)
        firebaseAnalytics = FirebaseAnalytics.getInstance(this)

        contentView.tabLayout.setupWithViewPager(contentView.pager)

        contentView.pager.adapter = DemoCollectionPagerAdapter(supportFragmentManager)
        schoolId = intent.getIntExtra("schoolId", -1)
        stucareId = intent.getIntExtra("stucareId", -1)
        accessToken = intent.getStringExtra("sessionToken")
        studentName = intent.getStringExtra("studentName")
        schoolUrl = intent.getStringExtra("baseUrl")

        progressDialog = ProgressDialog(this@ActivityClassesTabs)
        progressDialog.setTitle("Establishing secure connection")
        progressDialog.setMessage("Please wait, connecting to live class...")


        if(schoolUrl==null){
            Toast.makeText(
                this@ActivityClassesTabs,
                "Unknown error occurred, Please logout and login again..",
                Toast.LENGTH_LONG
            ).show()
        }else{
            NetworkClient.baseUrl = schoolUrl!!
        }

        Log.d("SENT_TOKEN", ""+accessToken);

        if(!ZoomSDK.getInstance().isInitialized){
            progressDialog.show()
            InitAuthSDKHelper.getInstance().initSDK(this, this)
        }
    }


    class DemoCollectionPagerAdapter(fm: FragmentManager) : FragmentPagerAdapter(fm) {

        override fun getCount(): Int = 2

        override fun getItem(i: Int): Fragment {
            if (i == 0) {
                return FrgLiveClasses()
            }
            return FrgUpcomingClasses()
        }

        override fun getPageTitle(position: Int): CharSequence {
            if (position == 0) {
                return "Today's"
            }

            return "Upcoming"
        }
    }


    override fun onZoomSDKInitializeResult(errorCode: Int, internalErrorCode: Int) {
        if (errorCode != ZoomError.ZOOM_ERROR_SUCCESS) {
            Toast.makeText(
                this,
                "Error: $errorCode, internalErrorCode=$internalErrorCode, Failed to initialize Zoom SDK, Please restart app ",
                Toast.LENGTH_LONG
            ).show()
        } else {
            ZoomSDK.getInstance().meetingSettingsHelper.enable720p(false)
            ZoomSDK.getInstance().meetingSettingsHelper.enableShowMyMeetingElapseTime(true)
            Toast.makeText(this, "Live Class Initialized.", Toast.LENGTH_LONG).show()
            if(progressDialog!=null && progressDialog.isShowing) progressDialog.dismiss()
        }
    }

    override fun onZoomAuthIdentityExpired() {
        TODO("Not yet implemented")
    }

}