package com.stucare.cloud_parent.video_lessons

import android.content.Intent
import android.view.View
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.SubjectHomeListViewBinding
import org.json.JSONArray

/**
 * Author: Ashish Walia(ashishwalia.me) on 03-11-2017.
 */

class AdapterSubjectHome(private val parentActivity: SubjectHome, val topicsData: JSONArray) : androidx.recyclerview.widget.RecyclerView.Adapter<AdapterSubjectHome.mViewHolder>() {



     open inner class mViewHolder(itemView: View) : androidx.recyclerview.widget.RecyclerView.ViewHolder(itemView) {
        open fun bindData(position: Int) {}
    }

    inner class ListViewHolder(var boundView: SubjectHomeListViewBinding) : mViewHolder(boundView.root) {
        override fun bindData(position: Int) {
            boundView.serialNumberText.text = (position + 1).toString()
            boundView.chapterName.text = topicsData.getJSONObject(position).getString("chapter_name")
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val listBinding = DataBindingUtil.inflate<SubjectHomeListViewBinding>(parentActivity.layoutInflater,
            R.layout.subject_home_list_view, parent, false)
        return ListViewHolder(listBinding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {

        holder.bindData(position)
        holder.itemView.isClickable = true
        holder.itemView.setOnClickListener {
            val intent = Intent(parentActivity, ActivityChapter::class.java)
            intent.putExtra("chapterId", topicsData.getJSONObject(position).getString("id"))
            intent.putExtra("sessionToken", parentActivity.accessToken)
            parentActivity.startActivity(intent)
        }


    }

    override fun getItemCount(): Int {
        return topicsData.length()
    }
}
