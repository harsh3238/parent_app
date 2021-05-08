package com.stucare.cloud_parent.tests

import android.Manifest
import android.app.Activity
import android.app.ProgressDialog
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.databinding.DataBindingUtil
import androidx.recyclerview.widget.LinearLayoutManager
import com.iceteck.silicompressorr.SiliCompressor
import com.karumi.dexter.Dexter
import com.karumi.dexter.PermissionToken
import com.karumi.dexter.listener.PermissionDeniedResponse
import com.karumi.dexter.listener.PermissionGrantedResponse
import com.karumi.dexter.listener.PermissionRequest
import com.karumi.dexter.listener.single.PermissionListener
import com.squareup.picasso.Picasso
import com.stucare.cloud_parent.AppCommonRvAdapter
import com.stucare.cloud_parent.DialogPhotoViewer
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ActivitySubjectiveSubmissionBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.jetbrains.anko.doAsync
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import toast
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.text.NumberFormat

class ActivitySubjectiveSubmission : AppCompatActivity() {

    private lateinit var mContentView: ActivitySubjectiveSubmissionBinding
    private lateinit var progressBar: ProgressDialog
    private val CAPTURE_IMAGE_REQUEST_CODE = 154


    private lateinit var mAdapter: AppCommonRvAdapter<String>
    private var mUserId: String = ""
    private var mStucareId: String = ""
    private var timeRemain: String = ""

    private var userSelectedTime = 0L
    var remainingTime: Long = 0
    lateinit var countDownTimer: CountDownTimer

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        super.onCreate(savedInstanceState)
        mContentView = DataBindingUtil.setContentView(this, R.layout.activity_subjective_submission)

        userSelectedTime = (60000 * 10);
        mUserId = intent.getStringExtra("user_id") ?: ""
        mStucareId = intent.getStringExtra("stucareId") ?: ""
        timeRemain = intent.getStringExtra("time_remain") ?: ""

        Log.d("TIME_REMAIN", timeRemain)

        progressBar = ProgressDialog(this)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")

        //mContentView.recyclerView.layoutManager = LinearLayoutManager(this)
        mContentView.recyclerView.layoutManager = LinearLayoutManager(
            this,
            LinearLayoutManager.HORIZONTAL,
            false
        )
        mAdapter = AppCommonRvAdapter(R.layout.subjective_test_submission_item) { view, item, position ->

                view.findViewById<TextView>(R.id.textView).text = "Attachment ${position + 1}"
                //view.findViewById<ImageView>(R.id.ivSubmissionImage).setImageURI(item.toString())

            if(item.startsWith("http")){
                Picasso.get().load(item).into(view.findViewById<ImageView>(R.id.ivSubmissionImage))
            }else{
                val f = File(item)
                Picasso.get().load(f).fit().centerInside().into(view.findViewById<ImageView>(R.id.ivSubmissionImage))
            }
                view.findViewById<ImageButton>(R.id.btnDelete).setOnClickListener {
                    val f = File(item)
                    f.delete()
                    populateRecyclerView()
                }
            }


        mAdapter.onItemClick = { pos, view, item ->
            val d = DialogPhotoViewer(
                this@ActivitySubjectiveSubmission,
                R.style.Theme_AppCompat_NoActionBar,
                item
            )
            d.show()
        }

        mContentView.recyclerView.adapter = mAdapter
        populateRecyclerView()

        mContentView.btnAddSubmission.setOnClickListener {

            Dexter.withActivity(this@ActivitySubjectiveSubmission)
                .withPermission(Manifest.permission.CAMERA)
                .withListener(object : PermissionListener {
                    override fun onPermissionGranted(response: PermissionGrantedResponse?) {
                        captureAnImage()
                    }

                    override fun onPermissionRationaleShouldBeShown(
                        permission: PermissionRequest?,
                        token: PermissionToken?
                    ) {
                        val PermissionRationaleDialog =
                            CustomAlertDialog(
                                this@ActivitySubjectiveSubmission,
                                R.style.PurpleTheme
                            )
                        PermissionRationaleDialog.setCancelable(false)
                        PermissionRationaleDialog.setTitle("Permission Required")
                        PermissionRationaleDialog.setMessage("In order to submit test, we require camera permission.")
                        PermissionRationaleDialog.positiveButton.setOnClickListener {
                            PermissionRationaleDialog.dismiss()
                            token?.continuePermissionRequest()
                        }
                        PermissionRationaleDialog.negativeButton.setOnClickListener {
                            PermissionRationaleDialog.dismiss()
                            token?.cancelPermissionRequest()
                        }
                        PermissionRationaleDialog.show()
                    }

                    override fun onPermissionDenied(response: PermissionDeniedResponse?) {
                        finish()
                    }
                }).check()
        }

        mContentView.buttonSubmit.setOnClickListener {
            submitRoutine()

        }

        if(timeRemain=="0"){
            startTimer()
        }
    }

    private fun captureAnImage() {
        val submissionsDir =
            File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}")
        if (!submissionsDir.exists()) {
            submissionsDir.mkdirs()
        }

        val tempCapturedFile =
            File(submissionsDir.absolutePath + "/" + System.currentTimeMillis() + ".jpg")
        val imageUri = FileProvider.getUriForFile(
            this@ActivitySubjectiveSubmission,
            packageName, tempCapturedFile
        )
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        intent.putExtra(MediaStore.EXTRA_OUTPUT, imageUri)
        startActivityForResult(intent, CAPTURE_IMAGE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            CAPTURE_IMAGE_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK) {
                    populateRecyclerView()
                }
            }
        }

    }

    private fun populateRecyclerView() {
        val filesDir =
            File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}")
        val files = filesDir.listFiles()
        if (files != null && files.isNotEmpty()) {
            val list = mutableListOf<String>()

            files.forEach {
                list.add(it.absolutePath)
            }

            if(list.size==0){
                mContentView.buttonSubmit.visibility = View.GONE
            }else{
                mContentView.buttonSubmit.visibility = View.VISIBLE
            }
            mAdapter.clearItems()
            mAdapter.addItems(list)
        } else {
            mAdapter.clearItems()
            mContentView.buttonSubmit.visibility = View.GONE
        }
    }

    private fun submitRoutine() {
        if (mUserId.isBlank()) {
            Toast.makeText(
                this@ActivitySubjectiveSubmission,
                "User not initialised, you may need to logout and login again",
                Toast.LENGTH_SHORT
            )
                .show()
            return
        }

        val submissionsDir =
            File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}")
        val files = submissionsDir.listFiles()
        if (files != null && files.isNotEmpty()) {

            val d = CustomAlertDialog(this, R.style.PurpleTheme)
            d.setCancelable(false)
            d.setTitle("Submit Test")
            d.setMessage("Are you sure you want to submit this test?")
            d.positiveButton.setOnClickListener {
                d.dismiss()
                compressAndZipFiles()
            }

            d.negativeButton.setOnClickListener {
                d.dismiss()
            }
            d.show()
        } else {
            Toast.makeText(
                this@ActivitySubjectiveSubmission,
                "No Submissions found",
                Toast.LENGTH_SHORT
            )
                .show()
        }
    }

    private fun compressAndZipFiles() {
        progressBar.show()
        progressBar.setCancelable(false)
        doAsync {
            val submissionsDir =
                File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}")
            val files = submissionsDir.listFiles()
            if (files != null && files.isNotEmpty()) {
                val list = mutableListOf<String>()
                val dFile = File(
                    cacheDir.absolutePath + "/submissions/submissions_${
                        intent.getStringExtra(
                            "test_id"
                        )
                    }_comp"
                )

                val document = PDDocument()
                var contentStream: PDPageContentStream? = null

                files.forEach {
                    val compressedFile = SiliCompressor.with(this@ActivitySubjectiveSubmission).compress(
                        it.absolutePath,
                        dFile,
                        true
                    )
                    list.add(compressedFile)

                    val page = PDPage()
                    document.addPage(page)

                    contentStream = PDPageContentStream(document, page)

                    val fileInputStream: InputStream = FileInputStream(compressedFile)

                    val ximage = JPEGFactory.createFromStream(document, fileInputStream)
                    contentStream!!.drawImage(ximage, 10f, 10f)
                    fileInputStream.close()
                    contentStream?.close()

                    Thread.sleep(1000)
                }

                // Save the final pdf document to a file
                val path = cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra(
                    "test_id"
                )}.pdf"
                document.save(path)
                document.close()
                val zipFileLocation = File(path)
                //val zipFileLocation = File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}.zip")
                //ZipManager().zip(list.toTypedArray(), zipFileLocation.absolutePath)
                dFile.deleteRecursively()
                submissionsDir.deleteRecursively()
                runOnUiThread {
                    progressBar.dismiss()
                    getSignedUrls(zipFileLocation)
                }
            } else {
                runOnUiThread {
                    toast("Failed to attach attachments")
                }
            }
        }
    }


    private fun getSignedUrls(fileToUpload: File) {
        progressBar.show()
        progressBar.setCancelable(false)

        val fileKEy = "flip/tests/test_${intent.getStringExtra("test_id")}/${mUserId}_${fileToUpload.name}"
        val call = NetworkClient.create().getSignedUrlForS3(
            fileKEy,
            intent.getStringExtra("accessToken") ?: ""
        )
        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            val signedUrl = jsonObject.getString("data")
                            val requestFile = fileToUpload.readBytes()
                                .toRequestBody(
                                    "application/pdf".toMediaTypeOrNull(),
                                    0
                                )
                            val upload = NetworkClient.create().uploadS3(signedUrl, requestFile)
                            upload.enqueue(object : Callback<String?> {
                                override fun onFailure(call: Call<String?>, t: Throwable) {
                                    progressBar.dismiss()
                                    Toast.makeText(
                                        this@ActivitySubjectiveSubmission,
                                        "Not uploaded",
                                        Toast.LENGTH_SHORT
                                    )
                                        .show()
                                }

                                override fun onResponse(
                                    call: Call<String?>,
                                    response: Response<String?>
                                ) {
                                    progressBar.dismiss()
                                    submitTests(fileKEy)
                                }
                            })
                        }

                    } else {
                        progressBar.dismiss()
                    }
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    this@ActivitySubjectiveSubmission,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }


        })
    }

    private fun submitTests(s3FileKey: String) {
        progressBar.show()
        progressBar.setCancelable(false)

        val call = NetworkClient.create().saveSubjectiveTests(
            intent.getStringExtra("stucareId") ?: "",
            intent.getStringExtra("test_id")!!,
            intent.getStringExtra("time_spent")!!,
            s3FileKey,
            intent.getStringExtra("accessToken") ?: ""
        )

        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {

                        var responseString = response.body();
                        if (responseString == "auth error") {
                            progressBar.dismiss()
                            showSessionDialog()
                            return
                        }

                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {

                            /*Toast.makeText(
                                this@ActivitySubjectiveSubmission,
                                "Test Submitted",
                                Toast.LENGTH_SHORT
                            ).show()*/

                            //to finish current activity and previous activity
                            val returnIntent = Intent()
                            returnIntent.putExtra("finish_status", "0")
                            setResult(RESULT_OK, returnIntent)
                            finish()
                        }

                    }
                    progressBar.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    this@ActivitySubjectiveSubmission,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }

        })
    }

    private fun startTimer() {
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
                compressAndZipFiles()
            }
        }.start()

    }


    fun showSessionDialog() {
        val d = CustomAlertDialog(this@ActivitySubjectiveSubmission, R.style.PurpleTheme)
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

    override fun onDestroy() {

        if(this :: countDownTimer.isInitialized && countDownTimer!=null){
            countDownTimer.cancel()
        }

        super.onDestroy()
    }
}
