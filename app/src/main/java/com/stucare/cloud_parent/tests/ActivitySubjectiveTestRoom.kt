package com.stucare.cloud_parent.tests

import android.app.ProgressDialog
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import com.otaliastudios.cameraview.CameraListener
import com.otaliastudios.cameraview.CameraOptions
import com.otaliastudios.cameraview.PictureResult
import com.squareup.picasso.Picasso
import com.stucare.cloud_parent.AppCommonRvAdapter
import com.stucare.cloud_parent.DialogPhotoViewer
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ActivitySubjectiveTestBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import okhttp3.ResponseBody
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import java.io.File
import java.io.FileOutputStream
import java.text.NumberFormat

class ActivitySubjectiveTestRoom : AppCompatActivity() {

    private lateinit var mContentView: ActivitySubjectiveTestBinding
    private lateinit var progressBar: ProgressDialog
    private val SUBMISSION_REQUEST_CODE = 155


    private lateinit var mAdapter: AppCommonRvAdapter<String>
    private var mUserId: String = ""

    private var userSelectedTime = 0L
    var remainingTime: Long = 0
    lateinit var countDownTimer: CountDownTimer
    private lateinit var monitorTest: String

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        super.onCreate(savedInstanceState)
        mContentView = DataBindingUtil.setContentView(this, R.layout.activity_subjective_test)

        monitorTest = intent.getStringExtra("monitor_test")

        if (intent.getIntExtra("monitor_student", 0) == 1) {
            mContentView.camera.setLifecycleOwner(this)
            mContentView.camera.addCameraListener(Listener())
        } else {
            mContentView.camera.visibility = View.GONE
        }

        userSelectedTime = intent.getLongExtra("duration", 0)
        mUserId = intent.getStringExtra("user_id") ?: ""

        progressBar = ProgressDialog(this)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")

        mContentView.btnAddSubmission.setOnClickListener {

            val mIntent = Intent(this@ActivitySubjectiveTestRoom,
                ActivitySubjectiveSubmission::class.java)

            mIntent.putExtra("user_id", intent.getStringExtra("stucareId"))
            mIntent.putExtra("stucareId", intent.getStringExtra("stucareId"))
            mIntent.putExtra("test_id", intent.getStringExtra("test_id"))
            mIntent.putExtra("accessToken", intent.getStringExtra("accessToken"))
            mIntent.putExtra("time_spent", getTimeSpent())
            mIntent.putExtra("time_remain", getTimeRemaining())
            startActivityForResult(mIntent, SUBMISSION_REQUEST_CODE)
        }

        mContentView.buttonSubmit.setOnClickListener {
            showSubmitDialog()
        }

        start()
        getQuestionPaper()
    }


    private fun loadImageQuestionPaper(imageUrl: String){
        if(imageUrl.startsWith("http")){
            Picasso.get().load(imageUrl).into(mContentView.ivQuestionPaper)
        }else{
            val f = File(imageUrl)
            Picasso.get().load(f).fit().centerInside().into(mContentView.ivQuestionPaper)
        }
    }

    private fun loadPDFQuestionPaper(filePath: String) {

        mContentView.pdfView.fromFile(File(filePath))
            .defaultPage(0)
            .enableAnnotationRendering(true)
            .spacing(10)
            .load()

    }


    private fun getQuestionPaper() {
        progressBar.show()

        val call = NetworkClient.create().getSubjectiveTest(
            intent.getStringExtra("test_id"),
            intent.getStringExtra("accessToken")
        )
        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") &&
                            jsonObject.getString("status") == "success"
                        ) {
                            val jsonArray = jsonObject.getJSONObject("data")
                            if (jsonArray.getString("media_type") == "image") {
                                val fileUrl = jsonArray.getString("file_url")

                                mContentView.ivQuestionPaper.visibility = View.VISIBLE;
                                mContentView.pdfView.visibility = View.GONE;

                                loadImageQuestionPaper(fileUrl)

                                /*val d = DialogPhotoViewer(
                                    this@ActivitySubjectiveTestRoom,
                                    R.style.Theme_AppCompat_NoActionBar,
                                    jsonArray.getString("file_url")
                                )
                                d.show()*/
                                progressBar.dismiss()
                            } else if (jsonArray.getString("media_type") == "pdf") {

                                mContentView.ivQuestionPaper.visibility = View.GONE;
                                mContentView.pdfView.visibility = View.VISIBLE;

                                val fileUrl = jsonArray.getString("file_url")
                                val fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1, fileUrl.length)
                                val imageCacheDir = File(cacheDir.absolutePath + "/" + fileName)

                                if (imageCacheDir.exists()) {
                                   /* val intent = Intent(
                                        this@ActivitySubjectiveTestRoom,
                                        PDFViewActivity::class.java
                                    )
                                    intent.putExtra("file", imageCacheDir.absolutePath)
                                    intent.putExtra("hash", "")
                                    startActivity(intent) */

                                    loadPDFQuestionPaper(imageCacheDir.absolutePath)
                                    progressBar.dismiss()
                                    return@let
                                }

                                val downloadCall = NetworkClient.create().downloadFile(fileUrl)
                                downloadCall.enqueue(object : Callback<ResponseBody?> {
                                    override fun onFailure(
                                        call: Call<ResponseBody?>,
                                        t: Throwable
                                    ) {
                                        Toast.makeText(
                                            this@ActivitySubjectiveTestRoom,
                                            "Download failed",
                                            Toast.LENGTH_SHORT
                                        )
                                            .show()
                                    }

                                    override fun onResponse(
                                        call: Call<ResponseBody?>,
                                        response: Response<ResponseBody?>
                                    ) {
                                        if (response.isSuccessful) {
                                            val imageCacheDir =
                                                File(cacheDir.absolutePath + "/" + fileName)
                                            if (imageCacheDir.exists()) {
                                                imageCacheDir.delete()
                                            }

                                            val input = response.body()?.byteStream()
                                            val fileOutputStream = FileOutputStream(imageCacheDir)
                                            input?.copyTo(fileOutputStream)

                                           /* val intent = Intent(
                                                this@ActivitySubjectiveTestRoom,
                                                PDFViewActivity::class.java
                                            )
                                            intent.putExtra("file", imageCacheDir.absolutePath)
                                            intent.putExtra("hash", "")
                                            startActivity(intent)*/
                                            loadPDFQuestionPaper(imageCacheDir.absolutePath)
                                            progressBar.dismiss()
                                        }
                                    }
                                })
                            }
                        }else{
                            Toast.makeText(
                                this@ActivitySubjectiveTestRoom,
                                "Unable to  load Question Paper, Please contact school...",
                                Toast.LENGTH_SHORT
                            ).show()
                            progressBar.dismiss()
                        }

                    } else {
                        progressBar.dismiss()
                    }
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    this@ActivitySubjectiveTestRoom,
                    "There has been error, Please try again...",
                    Toast.LENGTH_SHORT
                ).show()
            }


        })
    }


    private fun showSubmitDialog() {

        val builder = AlertDialog.Builder(this)
        //set title for alert dialog
        builder.setTitle("Submit Test")
        //set message for alert dialog
        builder.setMessage("Are you sure want to submit test, Please confirm.")
        builder.setIcon(android.R.drawable.ic_dialog_alert)

        //performing positive action
        builder.setPositiveButton("Submit"){dialogInterface, which ->

            val mIntent = Intent(this@ActivitySubjectiveTestRoom,
                ActivitySubjectiveSubmission::class.java)

            mIntent.putExtra("user_id", intent.getStringExtra("stucareId"))
            mIntent.putExtra("stucareId", intent.getStringExtra("stucareId"))
            mIntent.putExtra("test_id", intent.getStringExtra("test_id"))
            mIntent.putExtra("accessToken", intent.getStringExtra("accessToken"))
            mIntent.putExtra("time_spent", getTimeSpent())
            mIntent.putExtra("time_remain", getTimeRemaining());
            startActivityForResult(mIntent, SUBMISSION_REQUEST_CODE)
        }

        //performing negative action
        builder.setNegativeButton("Cancel"){dialogInterface, which ->

        }

        // Create the AlertDialog
        val alertDialog: AlertDialog = builder.create()
        alertDialog.setCancelable(false)
        alertDialog.show()
    }


    private fun showTimeoutDialog() {

        val builder = AlertDialog.Builder(this)
        //set title for alert dialog
        builder.setTitle("Time Over")
        //set message for alert dialog
        builder.setMessage("Your time is over, Please submit answer attachments on next screen")
        builder.setIcon(android.R.drawable.ic_dialog_alert)

        //performing positive action
        builder.setPositiveButton("Submit Answers"){dialogInterface, which ->

            val mIntent = Intent(this@ActivitySubjectiveTestRoom,
                ActivitySubjectiveSubmission::class.java)

            mIntent.putExtra("user_id", intent.getStringExtra("stucareId"))
            mIntent.putExtra("stucareId", intent.getStringExtra("stucareId"))
            mIntent.putExtra("test_id", intent.getStringExtra("test_id"))
            mIntent.putExtra("accessToken", intent.getStringExtra("accessToken"))
            mIntent.putExtra("time_spent", getTimeSpent())
            mIntent.putExtra("time_remain", "0");
            startActivityForResult(mIntent, SUBMISSION_REQUEST_CODE)
        }

        // Create the AlertDialog
        val alertDialog: AlertDialog = builder.create()
        alertDialog.setCancelable(false)
        alertDialog.setCanceledOnTouchOutside(false)
        alertDialog.show()
    }


    private fun start() {
        remainingTime = userSelectedTime + 1000

        countDownTimer = object : CountDownTimer(remainingTime, 1000) {

            override fun onTick(millisUntilFinished: Long) {
                remainingTime -= 1000
                // initial = current;

                val format = NumberFormat.getNumberInstance()
                format.minimumIntegerDigits = 2

                if (remainingTime < 0) {
                    remainingTime = 0L
                }

                val hours = ((remainingTime / (1000 * 60 * 60)) % 24).toInt()
                val minutes = (remainingTime / 60000).toInt()
                val seconds = (remainingTime % 60000 / 1000).toInt()
                mContentView.countDownTimer.text =
                    "${format.format(hours)}:${format.format(minutes)}:${format.format(seconds)}"

            }

            override fun onFinish() {
                mContentView.countDownTimer.text = "Finished"
                showTimeoutDialog()
            }
        }.start()

    }

    fun getTimeRemaining(): String {

        val hours = ((remainingTime / (1000 * 60 * 60)) % 24).toInt()
        val minutes = (remainingTime / 60000).toInt()
        val seconds = (remainingTime % 60000 / 1000).toInt()
        val format = NumberFormat.getNumberInstance()
        format.minimumIntegerDigits = 2
        return "${format.format(hours)}:${format.format(minutes)}:${format.format(seconds)}"
    }


    private fun getTimeSpent(): String {
        val totalTime = userSelectedTime * 60000 + 1000
        val timeSpentMilli = totalTime - remainingTime

        val hours = ((timeSpentMilli / (1000 * 60 * 60)) % 24).toInt()
        val minutes = (timeSpentMilli / 60000).toInt()
        val seconds = (timeSpentMilli % 60000 / 1000).toInt()
        val format = NumberFormat.getNumberInstance()
        format.minimumIntegerDigits = 2
        return "${format.format(hours)}:${format.format(minutes)}:${format.format(seconds)}"
    }

    fun showSessionDialog() {
        val d = CustomAlertDialog(this@ActivitySubjectiveTestRoom, R.style.PurpleTheme)
        d.setCancelable(false)
        d.setTitle("Auth Failure... !")
        d.setMessage("There is issue with authentication token, please login again.")
        d.positiveButton.text = "Ok"
        d.negativeButton.text = "Close"

        d.positiveButton.setOnClickListener {
            d.dismiss()
            this?.finish()
        }

        d.negativeButton.setOnClickListener {
            d.dismiss()
            this?.finish()
        }
        d.show()
    }

    inner class Listener : CameraListener() {
        override fun onCameraOpened(options: CameraOptions) {}

        override fun onPictureTaken(result: PictureResult) {
            super.onPictureTaken(result)

        }
    }

    override fun onBackPressed() {
        val d = CustomAlertDialog(this, R.style.PurpleTheme)
        d.setCancelable(false)
        d.setTitle("Leave Test?")
        d.setMessage("You will be disqualified if you leave the test? Continue?")
        d.positiveButton.setOnClickListener {
            d.dismiss()
            finish()
        }

        d.negativeButton.setOnClickListener {
            d.dismiss()
        }
        d.show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if(requestCode == SUBMISSION_REQUEST_CODE && resultCode == RESULT_OK){
            var finishStatus: String =  data!!.getStringExtra("finish_status")
            if(finishStatus=="0"){
                finish()
            }

        }
    }


}
