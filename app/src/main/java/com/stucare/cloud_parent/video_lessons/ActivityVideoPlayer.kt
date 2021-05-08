package com.stucare.cloud_parent.video_lessons

import android.content.res.Configuration
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.databinding.DataBindingUtil
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.youtube.player.YouTubeBaseActivity
import com.google.android.youtube.player.YouTubeInitializationResult
import com.google.android.youtube.player.YouTubePlayer
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.VideoPlayerBinding
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Author: Ashish Walia(ashishwalia.me) on 06-11-2017.
 */

class ActivityVideoPlayer : YouTubeBaseActivity() {

    var videoName = ""
    var videoId = ""
    var topicName = ""
    var topicId = ""
    private lateinit var videoList: JSONArray
    lateinit var contentView: VideoPlayerBinding
    lateinit var youtubePlayer: YouTubePlayer
    private var isViewLayoutDone = false
    private lateinit var bottomSheetBehavior: BottomSheetBehavior<*>
    private lateinit var playbackEventListener: YouTubePlayer.PlaybackEventListener

    private var shouldCleanWhenFinishes = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        contentView = DataBindingUtil.setContentView(this, R.layout.video_player)
        contentView.controller = this

        videoList = JSONArray(intent.getStringExtra("data"))
        val data = videoList.getJSONObject(0)
        videoName = data.getString("video_name")
        videoId = data.getString("link")
        topicName = data.getString("chapter_name")
        topicId = data.getString("chapter_id")


        initViews()
        setUpListenersForPlayer()
        initYoutubePlayer()


    }

    private fun initViews() {
        /**
         * Setting the Video data we already received in
         * the Intent
         */
        contentView.textViewVideoName.text = videoName
        contentView.textViewTopicName.text = topicName
        contentView.textViewTopicNameBottomSheet.text = topicName

        /**
         * Here we set the BottomSheet's height to be exactly
         * the same as the device's screen LEFT AFTER INFLATING the PLAYER
         * so when it's expanded, its top aligns with player's bottom
         */

        val viewTreeObserver = contentView.youTubeVideoPlayer.viewTreeObserver
        viewTreeObserver.addOnGlobalLayoutListener(ViewTreeObserver.OnGlobalLayoutListener {
            if (isViewLayoutDone) return@OnGlobalLayoutListener
            val content: FrameLayout = window.findViewById(android.R.id.content)

            val lp = androidx.coordinatorlayout.widget.CoordinatorLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_PX,
                            (content.height - contentView.youTubeVideoPlayer.height).toFloat(),
                            resources.displayMetrics).toInt())

            lp.behavior = BottomSheetBehavior<LinearLayout>()
            contentView.bottomSheet.layoutParams = lp
            bottomSheetBehavior = BottomSheetBehavior.from<LinearLayout>(contentView.bottomSheet)
            bottomSheetBehavior.isHideable = false
            bottomSheetBehavior.peekHeight = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                    60f, resources.displayMetrics).toInt()

            bottomSheetBehavior.setBottomSheetCallback(object : BottomSheetBehavior.BottomSheetCallback() {
                override fun onStateChanged(bottomSheet: View, newState: Int) {

                }

                override fun onSlide(bottomSheet: View, slideOffset: Float) {

                    contentView.dropDownArrow.rotation = 180 * slideOffset

                }
            })

            isViewLayoutDone = true
        })


        contentView.btmVisibleBit.setOnClickListener {
            if (bottomSheetBehavior.state == BottomSheetBehavior.STATE_EXPANDED)
                bottomSheetBehavior.setState(BottomSheetBehavior.STATE_COLLAPSED)
            else
                bottomSheetBehavior.setState(BottomSheetBehavior.STATE_EXPANDED)
        }


        contentView.btmRecyclerView.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)
        //contentView.btmRecyclerView.adapter = AdapterVideoPlayerPlaylist(this, videoList)

    }


    private fun setUpListenersForPlayer() {
        playbackEventListener = object : YouTubePlayer.PlaybackEventListener {
            override fun onSeekTo(p0: Int) {

            }

            override fun onBuffering(p0: Boolean) {

            }

            override fun onPlaying() {
            }

            override fun onStopped() {

            }

            override fun onPaused() {


            }
        }
    }

    private fun initYoutubePlayer() {
        contentView.youTubeVideoPlayer.initialize("AIzaSyD0npNsDGtL0RxZjlnKIbUKyFtZFvP7JeY", object : YouTubePlayer.OnInitializedListener {
            override fun onInitializationSuccess(provider: YouTubePlayer.Provider, youTubePlayer: YouTubePlayer, b: Boolean) {
                youTubePlayer.loadVideo(videoId)
                youtubePlayer = youTubePlayer
                youTubePlayer.setPlayerStyle(YouTubePlayer.PlayerStyle.MINIMAL);
                youTubePlayer.setShowFullscreenButton(false)
                youtubePlayer.setPlaybackEventListener(playbackEventListener)

            }

            override fun onInitializationFailure(provider: YouTubePlayer.Provider, youTubeInitializationResult: YouTubeInitializationResult) {

            }
        })
    }



    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (newConfig?.orientation == Configuration.ORIENTATION_PORTRAIT) youtubePlayer.setFullscreen(false)
        else youtubePlayer.setFullscreen(true)
    }
}
