/*
package org.flipacademy.mvps.tests.school_test

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import org.flipacademy.R
import org.flipacademy.databinding.FrgSchoolTestFinishedBinding
import org.flipacademy.interfaces.NetworkClient
import org.flipacademy.mvps.tests.customTests.ActivityAllQuestions
import org.flipacademy.utils.LoaderDialog
import org.flipacademy.utils.MyApplication
import javax.inject.Inject

class FrgTestFinished : Fragment() {

    lateinit var contentView: FrgSchoolTestFinishedBinding
    private lateinit var progressDialog: LoaderDialog

    @Inject
    lateinit var networkClient: NetworkClient

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        contentView = DataBindingUtil.inflate(inflater, R.layout.frg_school_test_finished, container, false)
        contentView.controller = this

        progressDialog = LoaderDialog(activity, R.style.PurpleTheme)
        (activity?.application as MyApplication).getAppComponent().inject(this)

        contentView.txtViewAttempted.text = (activity as com.stucare.cloud_parent.tests.SchoolTestRoom).getAttemptedQuesCount().toString()
        contentView.txtViewUnattempted.text = (activity as com.stucare.cloud_parent.tests.SchoolTestRoom).getUnAttemptedQuesCount().toString()
        contentView.txtViewSkipped.text = (activity as com.stucare.cloud_parent.tests.SchoolTestRoom).getSkipped().toString()
        return contentView.root

    }


    fun seeAllQuestions(v: View) {

        val bundle = Bundle()
        bundle.putSerializable("list", (activity as com.stucare.cloud_parent.tests.SchoolTestRoom).getQuestionList())

        val i = Intent(activity, ActivityAllQuestions::class.java)
        i.putExtra("data", bundle)
        activity?.startActivityForResult(i, 498)
    }

    fun submitTestClicked(v: View) {
        (activity as com.stucare.cloud_parent.tests.SchoolTestRoom).submitRoutine()
    }
}*/
