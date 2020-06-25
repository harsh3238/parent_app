/*
package org.flipacademy.mvps.classrooms

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import org.flipacademy.R
import org.flipacademy.databinding.ClassDetailsBinding
import org.json.JSONObject
import java.text.SimpleDateFormat

*/
/**
 * Author: Ashish Walia(ashishwalia.me) on 07-11-2017.
 *//*

class ActivityClassDetails : AppCompatActivity() {

  var format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
  var showFormat = SimpleDateFormat("hh:mm a',' E dd MMMM")

  lateinit var contentView: ClassDetailsBinding

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    contentView = DataBindingUtil.setContentView(this, R.layout.class_details)

    val data = JSONObject(intent.getStringExtra("data"))

     val d = format.parse("${data.getString("date_of_class")} ${data.getString("start_time")}")
    val dd = showFormat.format(d)
    contentView.txtTime.text = "$dd  |  ${data.getString("duration")} hr"
    contentView.txtDate2.text = "$dd  |  ${data.getString("duration")} hr"

   */
/* Picasso.get()
        .load(data.getString("image"))
        .into(contentView.imageVideo)*//*

    contentView.txtVideoName.text = data.getString("topic")
    contentView.txtTopicName.text = data.getString("topic")


  }
}*/
