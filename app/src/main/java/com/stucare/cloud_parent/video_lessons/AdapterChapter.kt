package com.stucare.cloud_parent.video_lessons

import android.content.Intent
import android.view.View
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import com.squareup.picasso.Picasso
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.SubjectHomeListViewBinding
import com.stucare.cloud_parent.databinding.TopicsPlaylistVideoViewBinding
import org.json.JSONArray

/**
 * Author: Ashish Walia(ashishwalia.me) on 03-11-2017.
 */

class AdapterChapter(private val parentActivity: ActivityChapter, val topicsData: JSONArray) : androidx.recyclerview.widget.RecyclerView.Adapter<AdapterChapter.mViewHolder>() {



     open inner class mViewHolder(itemView: View) : androidx.recyclerview.widget.RecyclerView.ViewHolder(itemView) {
        open fun bindData(position: Int) {}
    }

    internal inner class VideoViewHolder(var boundView: TopicsPlaylistVideoViewBinding) : mViewHolder(boundView.root) {

        override fun bindData(position: Int) {
            super.bindData(position)
            itemView.isClickable = true
            boundView.indexNumber.text = (position + 1).toString()

            val data = topicsData.getJSONObject(position)

            boundView.textViewVideoName.text = data.getString("video_name")
            val videoId = data.getString("link")
            Picasso.get().load("https://i1.ytimg.com/vi/$videoId/1.jpg").into(boundView.imageThumbnail)
            itemView.setOnClickListener {
                /*val intent = Intent(parentActivity, ActivityVideoPlayer::class.java)
                intent.putExtra("videoId", videoId)
                intent.putExtra("videoName", applicationInstance.topicVideosData[position].videoName)
                intent.putExtra("topicName", parentActivity.topicData.topic)
                intent.putExtra("topicId", parentActivity.topicData.id)
                intent.putExtra("subjectId", parentActivity.subjectData.subjectId)
                parentActivity.startActivity(intent)*/
            }
        }
    }



    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val videoBinding = DataBindingUtil.inflate<TopicsPlaylistVideoViewBinding>(parentActivity.layoutInflater,
            R.layout.topics_playlist_video_view, parent, false)
        return VideoViewHolder(videoBinding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {

        holder.bindData(position)
        holder.itemView.isClickable = true
        holder.itemView.setOnClickListener {

        }


    }

    override fun getItemCount(): Int {
        return topicsData.length()
    }
}
