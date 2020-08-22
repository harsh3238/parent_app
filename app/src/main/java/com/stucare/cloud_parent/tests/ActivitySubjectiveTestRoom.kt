package com.stucare.cloud_parent.tests

import android.Manifest
import android.app.Activity
import android.app.ProgressDialog
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.provider.MediaStore
import android.view.WindowManager
import android.widget.ImageButton
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
import com.stucare.cloud_parent.AppCommonRvAdapter
import com.stucare.cloud_parent.DialogPhotoViewer
import com.stucare.cloud_parent.PDFViewActivity
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ActivitySubjectiveTestBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import okhttp3.MediaType
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.ResponseBody
import org.jetbrains.anko.doAsync
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import toast
import java.io.File
import java.io.FileOutputStream
import java.text.NumberFormat

class ActivitySubjectiveTestRoom : AppCompatActivity() {

    private lateinit var mContentView: ActivitySubjectiveTestBinding
    private lateinit var progressBar: ProgressDialog
    private val CAPTURE_IMAGE_REQUEST_CODE = 154


    private lateinit var mAdapter: AppCommonRvAdapter<String>
    private var mUserId: String = ""

    private var userSelectedTime = 0L
    var remainingTime: Long = 0
    lateinit var countDownTimer: CountDownTimer

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
        mContentView = DataBindingUtil.setContentView(this, R.layout.activity_subjective_test)

        userSelectedTime = intent.getLongExtra("duration", 0)
        mUserId = intent.getStringExtra("user_id") ?: ""

        progressBar = ProgressDialog(this)
        progressBar.setCancelable(false)
        progressBar.isIndeterminate = true
        progressBar.setMessage("Please wait...")

        mContentView.recyclerView.layoutManager = LinearLayoutManager(this)
        mAdapter =
            AppCommonRvAdapter(R.layout.subjective_test_submission_item) { view, item, position ->

                view.findViewById<TextView>(R.id.textView).text = "Attachment ${position + 1}"

                view.findViewById<ImageButton>(R.id.btnDelete).setOnClickListener {
                    val f = File(item)
                    f.delete()
                    populateRecyclerView()
                }
            }

        mAdapter.onItemClick = { pos, view, item ->
            val d = DialogPhotoViewer(
                this@ActivitySubjectiveTestRoom,
                R.style.Theme_AppCompat_NoActionBar,
                item
            )
            d.show()
        }

        mContentView.recyclerView.adapter = mAdapter
        populateRecyclerView()

        mContentView.btnStart.setOnClickListener {
            getQuestionPaper()
        }

        mContentView.btnAddSubmission.setOnClickListener {
            Dexter.withActivity(this@ActivitySubjectiveTestRoom)
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
                            CustomAlertDialog(this@ActivitySubjectiveTestRoom, R.style.PurpleTheme)
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
        start()
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
            this@ActivitySubjectiveTestRoom,
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
            mAdapter.clearItems()
            mAdapter.addItems(list)
        } else {
            mAdapter.clearItems()
        }
    }

    private fun submitRoutine() {
        if (mUserId.isBlank()) {
            Toast.makeText(
                this@ActivitySubjectiveTestRoom,
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
                this@ActivitySubjectiveTestRoom,
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
                val dFile =
                    File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}_comp")
                files.forEach {
                    val compressedFile = SiliCompressor.with(this@ActivitySubjectiveTestRoom)
                        .compress(it.absolutePath, dFile, true)
                    list.add(compressedFile)
                    Thread.sleep(1000)
                }
                val zipFileLocation =
                    File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}.zip")
                ZipManager().zip(list.toTypedArray(), zipFileLocation.absolutePath)
                dFile.deleteRecursively()
                submissionsDir.deleteRecursively()
                runOnUiThread {
                    progressBar.dismiss()
                    getSignedUrls(zipFileLocation)
                }
            } else {
                runOnUiThread {
                    toast("No answer found")
                }
            }
        }
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
                                val d = DialogPhotoViewer(
                                    this@ActivitySubjectiveTestRoom,
                                    R.style.Theme_AppCompat_NoActionBar,
                                    jsonArray.getString("file_url")
                                )
                                d.show()
                                progressBar.dismiss()
                            } else if (jsonArray.getString("media_type") == "pdf") {
                                val fileUrl = jsonArray.getString("file_url")
                                val fileName =
                                    fileUrl.substring(fileUrl.lastIndexOf('/') + 1, fileUrl.length)
                                val imageCacheDir = File(cacheDir.absolutePath + "/" + fileName)
                                if (imageCacheDir.exists()) {
                                    val intent = Intent(
                                        this@ActivitySubjectiveTestRoom,
                                        PDFViewActivity::class.java
                                    )
                                    intent.putExtra("file", imageCacheDir.absolutePath)
                                    intent.putExtra("hash", "")
                                    startActivity(intent)
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
                                            val intent = Intent(
                                                this@ActivitySubjectiveTestRoom,
                                                PDFViewActivity::class.java
                                            )
                                            intent.putExtra("file", imageCacheDir.absolutePath)
                                            intent.putExtra("hash", "")
                                            startActivity(intent)
                                            progressBar.dismiss()
                                        }
                                    }
                                })
                            }
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
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }


        })
    }

    private fun getSignedUrls(fileToUpload: File) {
        progressBar.show()
        progressBar.setCancelable(false)


        val fileKEy =
            "flip/tests/test_${intent.getStringExtra("test_id")}/${mUserId}_${fileToUpload.name}"
        val call = NetworkClient.create().getSignedUrlForS3( fileKEy, intent.getStringExtra("accessToken"))
        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            val signedUrl = jsonObject.getString("data")
                            val requestFile = fileToUpload.readBytes()
                                .toRequestBody(
                                    "application/zip".toMediaTypeOrNull(),
                                    0
                                )
                            val upload = NetworkClient.create().uploadS3(signedUrl, requestFile)
                            upload.enqueue(object : Callback<String?> {
                                override fun onFailure(call: Call<String?>, t: Throwable) {
                                    progressBar.dismiss()
                                    Toast.makeText(
                                        this@ActivitySubjectiveTestRoom,
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
                    this@ActivitySubjectiveTestRoom,
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
            intent.getStringExtra("stucareId"),
            intent.getStringExtra("test_id")!!,
            getTimeSpent(),
            s3FileKey,
            intent.getStringExtra("accessToken")
        )

        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            Toast.makeText(
                                this@ActivitySubjectiveTestRoom,
                                "Test Submitted",
                                Toast.LENGTH_SHORT
                            )
                                .show()
                            finish()
                        }

                    }
                    progressBar.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressBar.dismiss()
                Toast.makeText(
                    this@ActivitySubjectiveTestRoom,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                )
                    .show()
            }


        })
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
            }
        }.start()

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
}
