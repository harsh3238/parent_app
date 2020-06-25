/*
//school registraion, employees registration, students, fees, attendance, transport, exams, homework

package org.flipacademy.mvps.tests.school_test

import android.app.Fragment
import android.app.FragmentManager
import android.os.Bundle
import android.view.View
import androidx.databinding.DataBindingUtil
import org.flipacademy.R
import org.flipacademy.databinding.CustomTabViewBinding
import org.flipacademy.models.ModelTestQuestion


*/
/**
 * Author: Ashish Walia(ashishwalia.me) on 21-11-2017.
 *//*

class AdapterSchoolTestRoom(fragmentManager: FragmentManager, val context: SchoolTestRoom, val mData: MutableList<ModelTestQuestion>) : androidx.legacy.app.FragmentStatePagerAdapter(fragmentManager) {

  override fun getItem(position: Int): Fragment {
    val bundle = Bundle()
    bundle.putSerializable("data", mData[position])

    val fragment = FragmentSchoolTestRoom()
    fragment.arguments = bundle

    return fragment
  }

  override fun getCount(): Int {
    return mData.size
  }

  override fun getPageTitle(position: Int): CharSequence {
    return (position + 1).toString()
  }

  fun getTabView(position: Int): View {
    val view = DataBindingUtil.inflate<CustomTabViewBinding>(context.layoutInflater,
        R.layout.custom_tab_view, null, false)
    view.txtView.text = (position + 1).toString()
    view.imageView.visibility = View.GONE
    return view.root
  }
}*/
