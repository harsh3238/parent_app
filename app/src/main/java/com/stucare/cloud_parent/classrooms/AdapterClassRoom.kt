/*
package org.flipacademy.mvps.classrooms

import android.content.ClipData.newPlainText
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.RecyclerView
import com.squareup.picasso.Picasso
import org.flipacademy.R
import org.flipacademy.databinding.ClassRoomPastClassItemBinding
import org.flipacademy.databinding.ClassRoomTitleItemBinding
import org.flipacademy.databinding.ClassroomRecyclerviewBinding
import org.flipacademy.utils.HorizontalLinearLayout
import org.flipacademy.utils.MyApplication
import org.json.JSONArray
import us.zoom.sdk.*
import java.text.SimpleDateFormat
import java.util.*


class AdapterClassRoom(val parentActivity: ActivityClassesTabs, val data: JSONArray, val goToClassClicked: (classId: String) -> Unit) : RecyclerView.Adapter<AdapterClassRoom.mViewHolder>() {
  var tFormat = SimpleDateFormat("HH:mm:ss")
  var tShowFormat = SimpleDateFormat("hh:mm a")

  var dFormat = SimpleDateFormat("yyyy-MM-dd")
  var dShowFormat = SimpleDateFormat("dd MMM")

  open inner class mViewHolder(itemView: View?) : RecyclerView.ViewHolder(itemView!!)


  inner class TitleViewHolder(val boundView: ClassRoomTitleItemBinding) : mViewHolder(boundView.root) {
    fun bindData(position: Int) {
      if (position == 0) {
        boundView.textView.text = "Upcoming & Currently Live Classes"
      } else {
        boundView.textView.text = "Past Classes"
      }
    }
  }

  inner class RecyclerViewHolder(val boundView: ClassroomRecyclerviewBinding) : mViewHolder(boundView.root) {

    init {
      boundView.recyclerView.isNestedScrollingEnabled = false
      boundView.recyclerView.layoutManager = HorizontalLinearLayout(parentActivity, androidx.recyclerview.widget.LinearLayoutManager.HORIZONTAL, false)

    }

    fun bindData() {
      boundView.recyclerView.adapter = AdapterClassRoomInner(parentActivity)
    }
  }

  inner class NormalViewHolder(val boundView: ClassRoomPastClassItemBinding) : mViewHolder(boundView.root) {
    fun bindData(position: Int) {
      Picasso.get()
          .load(getSubjectIcon(data.getJSONObject(position).getString("subject")))
          .into(boundView.imageVideo)
      boundView.txtVideoName.text = data.getJSONObject(position).getString("topic")
      boundView.txtViewName.text = data.getJSONObject(position).getString("teacher")

      val sTime = tShowFormat.format(tFormat.parse(data.getJSONObject(position).getString("start_time")))
      val eTime = tShowFormat.format(tFormat.parse(data.getJSONObject(position).getString("end_time")))
      val sDate = dShowFormat.format(dFormat.parse(data.getJSONObject(position).getString("date_of_class")))

      boundView.txtMeta.text = "${data.getJSONObject(position).getString("subject")} | $sDate | $sTime-$eTime"

      if (data.getJSONObject(position).getString("live_type") == "zoom") {
        boundView.txtViewRoomId.text = "ID: ${data.getJSONObject(position).getString("live_link")}"

        boundView.btnIdCopy.setOnClickListener {
          val clipboard = parentActivity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
          val clip = newPlainText("Zoom ID", data.getJSONObject(position).getString("live_link"))
          clipboard.setPrimaryClip(clip)
          Toast.makeText(parentActivity, "Copied", Toast.LENGTH_SHORT).show()
        }
      } else {
        boundView.txtViewRoomId.text = "YT: ${data.getJSONObject(position).getString("live_link")}"
        boundView.btnIdCopy.setOnClickListener {
          val clipboard = parentActivity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
          val clip = newPlainText("Youtube ID", data.getJSONObject(position).getString("live_link"))
          clipboard.setPrimaryClip(clip)
          Toast.makeText(parentActivity, "Copied", Toast.LENGTH_SHORT).show()
        }
      }

      if (data.getJSONObject(position).getString("live_password").isNotBlank()) {
        boundView.txtViewPassword.text = "Pwd: ${data.getJSONObject(position).getString("live_password")}"

        boundView.btnPassCopy.setOnClickListener {
          val clipboard = parentActivity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
          val clip = newPlainText("PASSWORD", data.getJSONObject(position).getString("live_password"))
          clipboard.setPrimaryClip(clip)
          Toast.makeText(parentActivity, "Copied", Toast.LENGTH_SHORT).show()
        }
      } else {
        boundView.txtViewPassword.visibility = View.GONE
        boundView.btnPassCopy.visibility = View.GONE
      }

      if (data.getJSONObject(position).getString("school_id") == "0") {
        boundView.txtContentType.text = "Flip"
        boundView.txtContentType.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(parentActivity, R.color.md_yellow_600))
      } else {
        boundView.txtContentType.text = "School"
        boundView.txtContentType.backgroundTintList = ColorStateList.valueOf(ContextCompat.getColor(parentActivity, R.color.md_green_500))

      }

      val ooo = data.getJSONObject(position).getString("start_ms").split('.')[0]
      val sMs = ooo.toLong() * 1000
      val now = Calendar.getInstance().timeInMillis
      val milLeft = sMs - now
      if (milLeft < 7200000) {
        boundView.txtTimeLeft.start(milLeft)
      } else {
        boundView.txtTimeLeft.visibility = View.INVISIBLE
      }


      boundView.btnGoToClass.setOnClickListener {
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
          opts.invite_options = InviteOptions.INVITE_VIA_EMAIL + InviteOptions.INVITE_VIA_SMS
          opts.no_audio = false
          opts.no_video = true
          opts.meeting_views_options = MeetingViewsOptions.NO_BUTTON_SHARE + MeetingViewsOptions.NO_TEXT_MEETING_ID + MeetingViewsOptions.NO_TEXT_PASSWORD
          opts.no_meeting_error_message = true

          val params = JoinMeetingParams()

          params.displayName = (parentActivity.application as MyApplication).usersData.fullName
          params.meetingNo = data.getJSONObject(position).getString("live_link")
          params.password = data.getJSONObject(position).getString("live_password")

          val response = meetingService.joinMeetingWithParams(parentActivity, params, opts)
          try {
            goToClassClicked(data.getJSONObject(position).getString("id"))
          }catch (e: Exception){
            e.printStackTrace()
          }
        }
      }

      itemView.setOnClickListener {
        val i = Intent(parentActivity, ActivityClassDetails::class.java)
        i.putExtra("data", data.getJSONObject(position).toString())
        parentActivity.startActivity(i)
      }
    }
  }


  override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
    if (viewType == VIEW_TYPE_TITLE) {
      val titleViewBinding = DataBindingUtil.inflate<ClassRoomTitleItemBinding>(parentActivity.layoutInflater,
          R.layout.class_room_title_item, parent, false)
      return TitleViewHolder(titleViewBinding)
    }
    if (viewType == VIEW_TYPE_NORMAL) {
      val titleViewBinding = DataBindingUtil.inflate<ClassRoomPastClassItemBinding>(parentActivity.layoutInflater,
          R.layout.class_room_past_class_item, parent, false)
      return NormalViewHolder(titleViewBinding)
    }
    val viewBinding = DataBindingUtil.inflate<ClassroomRecyclerviewBinding>(parentActivity.layoutInflater,
        R.layout.classroom_recyclerview, parent, false)
    return RecyclerViewHolder(viewBinding)
  }

  override fun onBindViewHolder(holder: mViewHolder, position: Int) {
    if (holder.itemViewType == VIEW_TYPE_TITLE)
      (holder as TitleViewHolder).bindData(position)
    else if (holder.itemViewType == VIEW_TYPE_RECYCLERVIEW)
      (holder as RecyclerViewHolder).bindData()
    else
      (holder as NormalViewHolder).bindData(position)
  }

  override fun getItemCount(): Int {
    return data.length()
  }

  override fun getItemViewType(position: Int): Int {
    // if (position == 0) return VIEW_TYPE_TITLE
    //if (position == 1 || position == 2) return VIEW_TYPE_RECYCLERVIEW
    return VIEW_TYPE_NORMAL
  }

  private fun getSubjectIcon(subName: String): Int {
    when(subName){
      "Physics" -> return R.drawable.class_physics
      "Biology" -> return R.drawable.class_bio
      "Chemistry" -> return R.drawable.class_chem
      "Civics" -> return R.drawable.class_civics
      "Economy" -> return R.drawable.class_eco
      "English" -> return R.drawable.class_eng
      "Geology" -> return R.drawable.class_geo
      "Hindi" -> return R.drawable.class_hindi
      "History" -> return R.drawable.class_history
      "Maths" -> return R.drawable.class_maths
      else -> return R.drawable.class_live
    }
  }


  companion object {
    val VIEW_TYPE_TITLE = 0
    val VIEW_TYPE_RECYCLERVIEW = 1
    val VIEW_TYPE_NORMAL = 2
  }


}
*/
