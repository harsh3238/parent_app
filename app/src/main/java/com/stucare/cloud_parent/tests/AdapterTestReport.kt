package com.stucare.cloud_parent.tests

import android.graphics.Color
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.TestReportItemBinding
import org.json.JSONArray
import org.json.JSONObject

/**
 * Author: Ashish Walia(ashishwalia.me) on 04-11-2017.
 */

class AdapterTestReport(private val parentActivity: ActivityTestReports, val answersData: JSONArray?, val callback: (data: JSONObject) -> Unit) : androidx.recyclerview.widget.RecyclerView.Adapter<AdapterTestReport.mViewHolder>() {

    inner class mViewHolder(var boundView: TestReportItemBinding) : androidx.recyclerview.widget.RecyclerView.ViewHolder(boundView.root) {
        fun bindData(position: Int) {
            boundView.txtViewNo.text = (position + 1).toString()

            val d = answersData?.getJSONObject(position)

            if(d?.getString("user_selected_answer") == "null"){
                boundView.viewIndicator.setBackgroundColor(parentActivity.resources.getColor(R.color.md_yellow_600))
            }else if(d?.getString("answer").equals(d?.getString("user_selected_answer"), ignoreCase = true)){

                boundView.viewIndicator.setBackgroundColor(parentActivity.resources.getColor(R.color.zm_green))
            }else{
                boundView.viewIndicator.setBackgroundColor(parentActivity.resources.getColor(R.color.zm_red))
            }

            itemView.setOnClickListener {
                d?.let {
                    callback(d)
                }
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val binding = DataBindingUtil.inflate<TestReportItemBinding>(parentActivity.layoutInflater,
                R.layout.test_report_item, parent, false)
        return mViewHolder(binding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {
        holder.bindData(position)

    }

    override fun getItemCount(): Int {
        return answersData?.length() ?: 0
    }
}
