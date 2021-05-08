package com.stucare.cloud_parent.tests

import android.app.ProgressDialog
import android.os.Bundle
import android.view.ViewTreeObserver
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import com.google.android.youtube.player.internal.i
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ActivityTestReportBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import org.json.JSONArray
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response

class ActivityTestReports : AppCompatActivity() {

    lateinit var mContentView: ActivityTestReportBinding
    private lateinit var progressBar: ProgressDialog


    private var answersData: JSONArray? = null


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mContentView = DataBindingUtil.setContentView(this, R.layout.activity_test_report)
        progressBar = ProgressDialog(this)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")

        val gridLayoutManager = androidx.recyclerview.widget.GridLayoutManager(this, 2)
        mContentView.recyclerView.layoutManager = gridLayoutManager

        mContentView.recyclerView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                mContentView.recyclerView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                val viewWidth = mContentView.recyclerView.measuredWidth
                val cardViewWidth = resources.getDimension(R.dimen.test_report_item_height_width)
                val newSpanCount = Math.ceil((viewWidth / cardViewWidth).toDouble()).toInt()
                gridLayoutManager.spanCount = newSpanCount
                gridLayoutManager.requestLayout()
            }
        })

        getReports()
    }

    private fun getReports() {
        progressBar.show()

        val call = NetworkClient.create().getObjectiveTestReport(
            intent.getStringExtra("stucareId") ?: "",
            intent.getStringExtra("test_id") ?: "",
            intent.getStringExtra("accessToken") ?: ""
        )
        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            answersData = jsonObject.getJSONArray("answers")
                            mContentView.recyclerView.adapter =
                                    AdapterTestReport(this@ActivityTestReports, answersData) { clickedData ->
                                        val modelTestQuestion = ModelTestQuestion(true)
                                        modelTestQuestion.questionId = clickedData.getString("id")
                                        modelTestQuestion.question = clickedData.getString("question")
                                        modelTestQuestion.optionA = clickedData.getString("option_a")
                                        modelTestQuestion.optionB = clickedData.getString("option_b")
                                        modelTestQuestion.optionC = clickedData.getString("option_c")
                                        modelTestQuestion.optionD = clickedData.getString("option_d")
                                        modelTestQuestion.answer = clickedData.getString("answer")
                                        modelTestQuestion.marks = clickedData.optString("marks")
                                        modelTestQuestion.usersResponse = clickedData.getString("user_selected_answer")
                                        val frg = FrgTestReportDetails()
                                        val bundle = Bundle()
                                        bundle.putSerializable("data", modelTestQuestion)
                                        frg.arguments = bundle
                                        fragmentManager.beginTransaction().add(R.id.fragmentContainer, frg).addToBackStack(null).commit()
                                    }
                            mContentView.txtTotalQuestions.text = answersData?.getJSONObject(0)?.getString("total_questions")
                            mContentView.txtAttemptedQuestions.text = answersData?.getJSONObject(0)?.getString("attempted_questions")
                            mContentView.txtCorrectAnswers.text = answersData?.getJSONObject(0)?.getString("correct_questions")
                            mContentView.tvMarksTotal.text = calculateMarksObtained()


                        }

                    }
                    progressBar.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(this@ActivityTestReports, "There has been error, please try again", Toast.LENGTH_SHORT)
                        .show()
            }

        })
    }

    private fun calculateMarksObtained(): String? {
        var totalMarks = 0

        try {
            for (i in 0 until (answersData?.length() ?: 0)) {
                val d = answersData?.getJSONObject(i)

                var marks = d?.getString("marks")
                var answer = d?.getString("answer")
                var user_answer = d?.getString("user_selected_answer")
                if(answer.equals(user_answer, ignoreCase = true)){
                    totalMarks = totalMarks+ (marks?.toInt() ?: 0)
                }
            }
        } catch (e: Exception) {
        }

        return totalMarks.toString()
    }

}