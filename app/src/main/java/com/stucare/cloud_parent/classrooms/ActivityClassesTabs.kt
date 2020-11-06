package com.stucare.cloud_parent.classrooms

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentPagerAdapter
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.TicketsTabActivityBinding
import com.stucare.cloud_parent.initsdk.InitAuthSDKCallback
import com.stucare.cloud_parent.initsdk.InitAuthSDKHelper
import us.zoom.sdk.ZoomError
import us.zoom.sdk.ZoomSDK


class ActivityClassesTabs : AppCompatActivity(), InitAuthSDKCallback {

    lateinit var contentView: TicketsTabActivityBinding
    var schoolId: Int? = null
    var stucareId: Int? = null
    var accessToken: String? = null
    var studentName: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "LIVE CLASSES"
        contentView = DataBindingUtil.setContentView(this, R.layout.tickets_tab_activity)
        contentView.tabLayout.setupWithViewPager(contentView.pager)

        contentView.pager.adapter = DemoCollectionPagerAdapter(supportFragmentManager)
        schoolId = intent.getIntExtra("schoolId", -1)
        stucareId = intent.getIntExtra("stucareId", -1)
        accessToken = intent.getStringExtra("sessionToken")
        studentName = intent.getStringExtra("studentName")

        InitAuthSDKHelper.getInstance().initSDK(this, this)
    }


    class DemoCollectionPagerAdapter(fm: FragmentManager) : FragmentPagerAdapter(fm) {

        override fun getCount(): Int = 2

        override fun getItem(i: Int): Fragment {
            if (i == 0) {
                return FrgClassRoomsMain()
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
                "Failed to initialize Zoom SDK. Error: $errorCode, internalErrorCode=$internalErrorCode",
                Toast.LENGTH_LONG
            ).show()
        } else {
            ZoomSDK.getInstance().meetingSettingsHelper.enable720p(false)
            ZoomSDK.getInstance().meetingSettingsHelper.enableShowMyMeetingElapseTime(true)
            Toast.makeText(this, "Live Class Initialized.", Toast.LENGTH_LONG).show()
        }
    }

    override fun onZoomAuthIdentityExpired() {
        TODO("Not yet implemented")
    }

}