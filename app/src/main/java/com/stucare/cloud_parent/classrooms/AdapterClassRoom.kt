

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.RecyclerView
import com.squareup.picasso.Picasso
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.classrooms.ActivityClassesTabs
import com.stucare.cloud_parent.databinding.ClassRoomPastClassItemBinding
import org.json.JSONArray
import us.zoom.sdk.*
import java.text.SimpleDateFormat
import java.util.*


class AdapterClassRoom(
    val parentActivity: ActivityClassesTabs, val data: JSONArray,
    val goToClassClicked: (classId: String) -> Unit
) : RecyclerView.Adapter<AdapterClassRoom.mViewHolder>() {
    var tFormat = SimpleDateFormat("HH:mm:ss")
    var tShowFormat = SimpleDateFormat("hh:mm a")

    var dFormat = SimpleDateFormat("yyyy-MM-dd")
    var dShowFormat = SimpleDateFormat("dd MMM")

    open inner class mViewHolder(itemView: View?) : RecyclerView.ViewHolder(itemView!!)


    inner class NormalViewHolder(val boundView: ClassRoomPastClassItemBinding) :
        mViewHolder(boundView.root) {
        fun bindData(position: Int) {
            Picasso.get()
                .load(getSubjectIcon(data.getJSONObject(position).getString("subject")))
                .into(boundView.imageVideo)
            boundView.txtVideoName.text = data.getJSONObject(position).getString("topic")
            boundView.txtViewName.text = data.getJSONObject(position).getString("teacher")

            val sTime = tShowFormat.format(
                tFormat.parse(
                    data.getJSONObject(position).getString("start_time")
                )
            )
            val eTime = tShowFormat.format(
                tFormat.parse(
                    data.getJSONObject(position).getString("end_time")
                )
            )
            val sDate = dShowFormat.format(
                dFormat.parse(
                    data.getJSONObject(position).getString("date_of_class")
                )
            )

            boundView.txtMeta.text =
                "${data.getJSONObject(position).getString("subject")} | $sDate | $sTime-$eTime"

            if (data.getJSONObject(position).getString("live_type") == "zoom") {
                boundView.txtViewRoomId.text =
                    "ID: ${data.getJSONObject(position).getString("live_link")}"

            } else {
                boundView.txtViewRoomId.text =
                    "YT: ${data.getJSONObject(position).getString("live_link")}"
            }

            if (data.getJSONObject(position).getString("live_password").isNotBlank()) {
                boundView.txtViewPassword.text =
                    "Pwd: ${data.getJSONObject(position).getString("live_password")}"


            } else {
                boundView.txtViewPassword.visibility = View.GONE
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
                if(data.getJSONObject(position).getString("live_type")=="gmeet"){

                    try {
                        goToClassClicked(data.getJSONObject(position).getString("id"))
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }

                    Log.d("LIVE_CLASS", "GMEET")
                    val mapIntent: Intent = Uri.parse(
                        data.getJSONObject(position).getString("live_link")
                    ).let { liveClass ->
                        Intent(Intent.ACTION_VIEW, liveClass)
                    }
                    try {
                        parentActivity.startActivity(mapIntent);
                    } catch (e: ActivityNotFoundException) {
                        Toast.makeText(
                            parentActivity,
                            "No app found to start GMeet live class",
                            Toast.LENGTH_LONG
                        ).show()
                    }


                }else if(data.getJSONObject(position).getString("live_type")=="youtube"){
                    Log.d("LIVE_CLASS", "YOUTUBE")

                }else if(data.getJSONObject(position).getString("live_type")=="zoom"){
                    Log.d("LIVE_CLASS", "ZOOM")
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

                        params.displayName = parentActivity.studentName
                        params.meetingNo = data.getJSONObject(position).getString("live_link")
                        params.password = data.getJSONObject(position).getString("live_password")

                        val response =
                            meetingService.joinMeetingWithParams(parentActivity, params, opts)
                        try {
                            goToClassClicked(data.getJSONObject(position).getString("id"))
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                }

            }

            itemView.setOnClickListener {
                /*val i = Intent(parentActivity, ActivityClassDetails::class.java)
                i.putExtra("data", data.getJSONObject(position).toString())
                parentActivity.startActivity(i)*/
            }
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val titleViewBinding = DataBindingUtil.inflate<ClassRoomPastClassItemBinding>(
            parentActivity.layoutInflater,
            R.layout.class_room_past_class_item, parent, false
        )
        return NormalViewHolder(titleViewBinding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {
        (holder as NormalViewHolder).bindData(position)
    }

    override fun getItemCount(): Int {
        return data.length()
    }


    private fun getSubjectIcon(subName: String): Int {
        when (subName) {
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

}
