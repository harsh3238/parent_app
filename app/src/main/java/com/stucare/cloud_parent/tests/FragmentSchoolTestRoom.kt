/*
package org.flipacademy.mvps.tests.school_test

import android.app.Fragment
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import org.flipacademy.R
import org.flipacademy.databinding.FragmentSchoolTestRoomBinding
import org.flipacademy.models.ModelTestQuestion

*/
/**
 * Author: Ashish Walia(ashishwalia.me) on 21-11-2017.
 *//*


class FragmentSchoolTestRoom : Fragment() {

  lateinit var contentView: FragmentSchoolTestRoomBinding
  var mData: ModelTestQuestion? = null
  private var mSelectedOptionId = -1

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    mData = arguments.getSerializable("data") as ModelTestQuestion
  }

  override fun onCreateView(inflater: LayoutInflater?, container: ViewGroup?, savedInstanceState: Bundle?): View {
    contentView = DataBindingUtil.inflate(inflater!!, R.layout.fragment_school_test_room, container, false)
    contentView.controller = this


    contentView.formulaTwo.text = mData?.question
    contentView.itemContentViewA.text = mData?.optionA
    contentView.itemContentViewB.text = mData?.optionB
    contentView.itemContentViewC.text = mData?.optionC
    contentView.itemContentViewD.text = mData?.optionD

    mSelectedOptionId = mData?.userSelectedAnswer!!

    mData?.let {
      if (it.isReport) {
        showReport()
      } else {
        refreshData()
      }
    }
    return contentView.root
  }

  fun onClickOption(v: View?) {
    mData?.let {
      if (!it.isReport) {
        mSelectedOptionId = if (v?.id == mSelectedOptionId) -1 else v!!.id
        mData?.userSelectedAnswer = mSelectedOptionId
        mData?.userSelectedOption = v.tag.toString()
        refreshData()
      }
      (activity as SchoolTestRoom).capturePictureSnapshot(it.questionId)
    }

  }

  private fun refreshData() {
    val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
    val f: Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 1f, activity.resources.displayMetrics).toInt()
    d.setStroke(f, ContextCompat.getColor(activity, R.color.cyan_light))

    for (i in 0..3) {
      when (i) {
        0 -> {
          if (mSelectedOptionId == contentView.optionClickerA.id) {
            contentView.backgroundViewA.background = d

            contentView.optionAlphabetIconA.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
          } else {
            contentView.backgroundViewA.background = null
            contentView.optionAlphabetIconA.setColorFilter(ContextCompat.getColor(activity, R.color.text_light))
          }
        }

        1 -> {
          if (mSelectedOptionId == contentView.optionClickerB.id) {
            contentView.backgroundViewB.background = d

            contentView.optionAlphabetIconB.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
          } else {
            contentView.backgroundViewB.background = null
            contentView.optionAlphabetIconB.setColorFilter(ContextCompat.getColor(activity, R.color.text_light))
          }
        }
        2 -> {
          if (mSelectedOptionId == contentView.optionClickerC.id) {
            contentView.backgroundViewC.background = d

            contentView.optionAlphabetIconC.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
          } else {
            contentView.backgroundViewC.background = null
            contentView.optionAlphabetIconC.setColorFilter(ContextCompat.getColor(activity, R.color.text_light))
          }
        }
        3 -> {
          if (mSelectedOptionId == contentView.optionClickerD.id) {
            contentView.backgroundViewD.background = d

            contentView.optionAlphabetIconD.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
          } else {
            contentView.backgroundViewD.background = null
            contentView.optionAlphabetIconD.setColorFilter(ContextCompat.getColor(activity, R.color.text_light))
          }
        }
      }
    }

  }


  private fun showReport() {
    val f: Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 1f, activity.resources.displayMetrics).toInt()

    mData?.let {
      for (i in 0..3) {
        when (i) {
          0 -> {
            if (it.usersResponse.equals("a", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.cyan_light))
              contentView.backgroundViewA.background = d
              contentView.optionAlphabetIconA.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
            }

            if (it.answer.equals("a", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.green_dark))
              contentView.backgroundViewA.background = d
              contentView.optionAlphabetIconA.setColorFilter(ContextCompat.getColor(activity, R.color.green_dark))
            }

          }

          1 -> {
            if (it.usersResponse.equals("b", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.cyan_light))
              contentView.backgroundViewB.background = d
              contentView.optionAlphabetIconB.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
            }

            if (it.answer.equals("b", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.green_dark))
              contentView.backgroundViewB.background = d
              contentView.optionAlphabetIconB.setColorFilter(ContextCompat.getColor(activity, R.color.green_dark))
            }
          }
          2 -> {
            if (it.usersResponse.equals("c", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.cyan_light))
              contentView.backgroundViewC.background = d
              contentView.optionAlphabetIconC.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
            }

            if (it.answer.equals("c", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.green_dark))
              contentView.backgroundViewC.background = d
              contentView.optionAlphabetIconC.setColorFilter(ContextCompat.getColor(activity, R.color.green_dark))
            }
          }
          3 -> {
            if (it.usersResponse.equals("d", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.cyan_light))
              contentView.backgroundViewD.background = d
              contentView.optionAlphabetIconD.setColorFilter(ContextCompat.getColor(activity, R.color.cyan_light))
            }

            if (it.answer.equals("d", true)) {
              val d: GradientDrawable = activity.resources.getDrawable(R.drawable.bk_holo_rounded) as GradientDrawable
              d.setStroke(f, ContextCompat.getColor(activity, R.color.green_dark))
              contentView.backgroundViewD.background = d
              contentView.optionAlphabetIconD.setColorFilter(ContextCompat.getColor(activity, R.color.green_dark))
            }
          }
        }
      }

    }


  }

}*/
