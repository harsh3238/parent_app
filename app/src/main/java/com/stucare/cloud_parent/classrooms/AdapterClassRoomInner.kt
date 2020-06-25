/*
package org.flipacademy.mvps.classrooms

import android.content.Intent
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.RecyclerView
import com.squareup.picasso.Picasso
import org.flipacademy.R
import org.flipacademy.databinding.ClassRoomLiveClassItemBinding

*/
/**
 * Author: Ashish Walia(ashishwalia.me) on 08-11-2017.
 *//*

class AdapterClassRoomInner(val parentActivity: ActivityClassesTabs) : RecyclerView.Adapter<AdapterClassRoomInner.mViewHolder>() {

  inner class mViewHolder(val boundView: ClassRoomLiveClassItemBinding) : RecyclerView.ViewHolder(boundView.root) {

    fun bindData() {
      Picasso.get()
          .load("https://img.youtube.com/vi/g0XzEgYWFQ8/maxresdefault.jpg")
          .into(boundView.imageVideo)
      itemView.setOnClickListener {
        parentActivity.startActivity(Intent(parentActivity, ActivityClassDetails::class.java))
      }
    }
  }


  override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
    val viewBinding = DataBindingUtil.inflate<ClassRoomLiveClassItemBinding>(parentActivity.layoutInflater,
        R.layout.class_room_live_class_item, parent, false)
    return mViewHolder(viewBinding)
  }

  override fun onBindViewHolder(holder: mViewHolder, position: Int) {
    holder.bindData()

  }

  override fun getItemCount(): Int {
    return 8
  }


}*/
