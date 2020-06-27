package com.stucare.cloud_parent.tests

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.databinding.DataBindingUtil
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.CustomAlertDialogBinding


class CustomAlertDialog : Dialog {

    var contentViewMain: CustomAlertDialogBinding
    var mActivity: Activity
    var positiveButton: Button
    var negativeButton: Button
    var marginView: View

    constructor(context: Context?, themeResId: Int) : super(context!!, themeResId) {
        mActivity = context as Activity
        contentViewMain = DataBindingUtil.inflate(mActivity.layoutInflater, R.layout.custom_alert_dialog, null, false)
        positiveButton = contentViewMain.buttonPositive
        negativeButton = contentViewMain.buttonNegative
        marginView = contentViewMain.marginView
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(contentViewMain.root)
        window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))

    }

    fun setTitle(title: String) {
        contentViewMain.textTitle.text = title
    }

    fun setMessage(message: String) {
        contentViewMain.textMessage.text = message
    }

}