package com.stucare.cloud_parent.tests

import android.content.Intent
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.FragmentActivity
import androidx.recyclerview.widget.RecyclerView
import com.stucare.cloud_parent.MainActivity
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.SchoolTestListItemBinding
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit


class AdapterSchoolTestsMain(private val parentActivity: FragmentActivity,
                             val mData: JSONArray, val mStucareId: String, val mSchoolId: String, val accessToken: String) : RecyclerView.Adapter<AdapterSchoolTestsMain.mViewHolder>() {
    val inTimestampFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
    val inTime = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    val outTime = SimpleDateFormat("hh:mm a", Locale.getDefault())

    inner class mViewHolder(var boundView: SchoolTestListItemBinding) : RecyclerView.ViewHolder(boundView.root) {
        fun bindData(position: Int) {
            val data = mData.getJSONObject(position)
            boundView.txtViewTitle.text = data.getString("test_name")
            boundView.txtViewSubText.text = "${data.getString("start_date")} at ${outTime.format(inTime.parse(data.getString("start_time")))}"

            if (data.getString("is_attempted").toInt() == 1) {
                boundView.attempted.visibility = View.VISIBLE
                boundView.btnStart.visibility = View.GONE
                if (data.getString("test_format") == "objective"){
                    itemView.setOnClickListener {
                        val intent = Intent(parentActivity, ActivityTestReports::class.java)
                        intent.putExtra("test_id", data.getInt("id").toString())
                        intent.putExtra("stucareId", mStucareId)
                        intent.putExtra("accessToken", accessToken)

                        parentActivity.startActivity(intent)
                    }
                }
            } else {
                boundView.attempted.visibility = View.GONE

                val intent = if (data.getString("test_format") == "objective")
                    Intent(parentActivity, SchoolTestRoom::class.java)
                else Intent(parentActivity, ActivitySubjectiveTestRoom::class.java)
                intent.putExtra("school_id", mSchoolId)
                intent.putExtra("accessToken", accessToken)

                if (data.getString("is_active").toInt() == 1 && data.getString("has_passed").toInt() == 0) {
                    boundView.btnInactive.visibility = View.GONE
                    if (data.getString("type") == "time_bound") {
                        val classTimeStamp =
                                inTimestampFormat.parse("${data.getString("start_date")} ${data.getString("start_time")}")
                        val duration: Long =
                                classTimeStamp.time - Calendar.getInstance().time.time
                        val diffInMinutes = TimeUnit.MILLISECONDS.toMinutes(duration)

                        val testEndTimeStamp =
                                inTimestampFormat.parse("${data.getString("start_date")} ${data.getString("end_time")}")
                        val testTimeLeft: Long =
                                testEndTimeStamp.time - Calendar.getInstance().time.time
                        val testTimeLeftInMinutes = TimeUnit.MILLISECONDS.toMinutes(testTimeLeft)

                        if (diffInMinutes <= 1 && testTimeLeftInMinutes > 1) {
                            boundView.btnStart.visibility = View.VISIBLE
                        } else {
                            boundView.btnStart.visibility = View.GONE
                        }

                        if (data.getString("is_attempted").toInt() == 1) {
                            boundView.btnStart.visibility = View.GONE
                        } else {
                            boundView.btnStart.visibility = View.VISIBLE
                        }

                        boundView.btnStart.setOnClickListener {
                            val testTimeLeft: Long =
                                    testEndTimeStamp.time - Calendar.getInstance().time.time
                            val testTimeLeftInMinutes = TimeUnit.MILLISECONDS.toMinutes(testTimeLeft)
                            if (diffInMinutes <= 1 && testTimeLeftInMinutes > 1 && data.getString("is_attempted").toInt() != 1) {
                                if (mStucareId.isNotBlank()) {
                                    intent.putExtra("test_id", data.getInt("id").toString())
                                    intent.putExtra("duration", testTimeLeft)
                                    intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                    intent.putExtra("user_id", mStucareId)
                                    parentActivity.startActivity(intent)
                                } else {
                                    Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                            .show()
                                }
                            } else {
                                Toast.makeText(parentActivity, "Test Can Only Be Joined Before 1 Minute", Toast.LENGTH_SHORT).show()
                            }
                        }

                        itemView.setOnClickListener { v ->
                            val testTimeLeft: Long =
                                    testEndTimeStamp.time - Calendar.getInstance().time.time
                            val testTimeLeftInMinutes = TimeUnit.MILLISECONDS.toMinutes(testTimeLeft)
                            if (diffInMinutes <= 1 && testTimeLeftInMinutes > 1 && data.getString("is_attempted").toInt() != 1) {
                                if (mStucareId.isNotBlank()) {
                                    intent.putExtra("test_id", data.getInt("id").toString())
                                    intent.putExtra("duration", testTimeLeft)
                                    intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                    intent.putExtra("user_id", mStucareId)
                                    parentActivity.startActivity(intent)
                                } else {
                                    Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                            .show()
                                }
                            } else {
                                Toast.makeText(parentActivity, "Test Can Only Be Joined Before 1 Minute", Toast.LENGTH_SHORT).show()
                            }

                        }
                    } else {
                        if (data.getString("is_attempted").toInt() == 1) {
                            boundView.btnStart.visibility = View.GONE
                        } else {
                            boundView.btnStart.visibility = View.VISIBLE
                        }
                        itemView.setOnClickListener { v ->
                            if (data.getString("is_attempted").toInt() != 1) {
                                if (mStucareId.isNotBlank()) {
                                    intent.putExtra("test_id", data.getInt("id").toString())
                                    intent.putExtra("duration", data.getLong("duration"))
                                    intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                    intent.putExtra("user_id", mStucareId)
                                    parentActivity.startActivity(intent)
                                } else {
                                    Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                            .show()
                                }
                            }

                        }
                        boundView.btnStart.setOnClickListener {
                            if (data.getString("is_attempted").toInt() != 1) {
                                if (mStucareId.isNotBlank()) {
                                    intent.putExtra("test_id", data.getInt("id").toString())
                                    intent.putExtra("duration", data.getLong("duration"))
                                    intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                    intent.putExtra("user_id", mStucareId)
                                    parentActivity.startActivity(intent)
                                } else {
                                    Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                            .show()
                                }
                            }
                        }
                    }
                } else if (data.getString("is_active").toInt() == 1 && data.getString("type") != "time_bound") {
                    boundView.btnInactive.visibility = View.GONE
                    if (data.getString("is_attempted").toInt() == 1) {
                        boundView.btnStart.visibility = View.GONE
                    } else {
                        boundView.btnStart.visibility = View.VISIBLE
                    }
                    itemView.setOnClickListener { v ->
                        if (data.getString("is_attempted").toInt() != 1) {
                            if (mStucareId.isNotBlank()) {
                                intent.putExtra("test_id", data.getInt("id").toString())
                                intent.putExtra("duration", data.getLong("duration"))
                                intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                intent.putExtra("user_id", mStucareId)
                                parentActivity.startActivity(intent)
                            } else {
                                Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                        .show()
                            }
                        }

                    }
                    boundView.btnStart.setOnClickListener {
                        if (data.getString("is_attempted").toInt() != 1) {
                            if (mStucareId.isNotBlank()) {
                                intent.putExtra("test_id", data.getInt("id").toString())
                                intent.putExtra("duration", data.getLong("duration"))
                                intent.putExtra("monitor_student", data.getInt("monitor_student"))
                                intent.putExtra("user_id", mStucareId)
                                parentActivity.startActivity(intent)
                            } else {
                                Toast.makeText(parentActivity, "User not initialised, you may need to logout and login again", Toast.LENGTH_SHORT)
                                        .show()
                            }
                        }
                    }
                } else {
                    boundView.btnInactive.visibility = View.VISIBLE
                }
            }

        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val binding = DataBindingUtil.inflate<SchoolTestListItemBinding>(parentActivity.layoutInflater,
                R.layout.school_test_list_item, parent, false)
        return mViewHolder(binding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {
        holder.bindData(position)

    }

    override fun getItemCount(): Int {
        return mData.length()
    }
}
