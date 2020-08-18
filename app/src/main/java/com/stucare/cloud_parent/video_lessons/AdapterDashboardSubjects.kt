package com.stucare.cloud_parent.video_lessons

import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import com.squareup.picasso.Picasso
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.SubjectItemViewBinding
import org.json.JSONArray

class AdapterDashboardSubjects(
    private val parentActivity: ActivityVideoLessons,
    private val data: JSONArray
) : androidx.recyclerview.widget.RecyclerView.Adapter<AdapterDashboardSubjects.mViewHolder>() {


    inner class mViewHolder(var boundContentView: SubjectItemViewBinding) :
        androidx.recyclerview.widget.RecyclerView.ViewHolder(boundContentView.root) {

        fun bindData(position: Int) {
            Picasso.get()
                .load(getSubjectIcon(data.getJSONObject(position).getString("subject_name")))
                .into(boundContentView.subjectIcon)
            boundContentView.subjectName.text =
                data.getJSONObject(position).getString("subject_name")
        }
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): mViewHolder {
        val binding = DataBindingUtil.inflate<SubjectItemViewBinding>(
            parentActivity.layoutInflater,
            R.layout.subject_item_view, parent, false
        )
        binding.controller = this
        return mViewHolder(binding)
    }

    override fun onBindViewHolder(holder: mViewHolder, position: Int) {
        holder.bindData(position)
        holder.itemView.isClickable = true
        holder.itemView.setOnClickListener {
            /*val intent = Intent(parentActivity, SubjectHome::class.java)
            intent.putExtra(Constants.SubjectData, applicationInstance.parsedSubjectsData[position])
            parentActivity.startActivity(intent)*/
        }
    }

    override fun getItemCount(): Int {
        return data.length()
    }

    private fun getSubjectIcon(subName: String): Int {
        return when {
            subName.toLowerCase().contains("physics") -> R.drawable.physics
            subName.toLowerCase().contains("account") -> R.drawable.accountancy
            subName.toLowerCase().contains("bio") -> R.drawable.biology
            subName.toLowerCase().contains("buss") -> R.drawable.businessstudies
            subName.toLowerCase().contains("civi") -> R.drawable.civics
            subName.toLowerCase().contains("chem") -> R.drawable.chemistry
            subName.toLowerCase().contains("geo") -> R.drawable.geography
            subName.toLowerCase().contains("history") -> R.drawable.history
            subName.toLowerCase().contains("maths") -> R.drawable.maths
            subName.toLowerCase().contains("science") -> R.drawable.science
            subName.toLowerCase().contains("english") -> R.drawable.english
            else -> R.drawable.science
        }
    }


}
