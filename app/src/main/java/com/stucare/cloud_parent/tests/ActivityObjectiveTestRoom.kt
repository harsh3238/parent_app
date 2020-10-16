package com.stucare.cloud_parent.tests

import android.app.Activity
import android.app.ProgressDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PorterDuff
import android.os.Bundle
import android.os.CountDownTimer
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import androidx.vectordrawable.graphics.drawable.VectorDrawableCompat
import com.google.android.material.tabs.TabLayout
import com.iceteck.silicompressorr.SiliCompressor
import com.otaliastudios.cameraview.CameraListener
import com.otaliastudios.cameraview.CameraOptions
import com.otaliastudios.cameraview.FileCallback
import com.otaliastudios.cameraview.PictureResult
import com.otaliastudios.cameraview.controls.Preview
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ActivityObjectiveTestRoomBinding
import com.stucare.cloud_parent.retrofit.NetworkClient
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.jetbrains.anko.doAsync
import org.json.JSONArray
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import toast
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.net.URISyntaxException
import java.text.NumberFormat
import java.util.*
import android.util.Log.d as d1


class ActivityObjectiveTestRoom : AppCompatActivity() {

    lateinit var contentView: ActivityObjectiveTestRoomBinding
    private lateinit var progressDialog: ProgressDialog
    private var userSelectedTime = 0L
    var remainingTime: Long = 0
    lateinit var countDownTimer: CountDownTimer

    private val mQuestionsList = mutableListOf<ModelTestQuestion>()
    private var mLastAnsweredQuestionId = ""

    private lateinit var mUserId: String
    private lateinit var mSchoolId: String
    private lateinit var accessToken: String
    private lateinit var monitorTest: String
    private var monitorStudent: Int = 0;


    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
        contentView = DataBindingUtil.setContentView(this, R.layout.activity_objective_test_room)

        monitorTest = intent.getStringExtra("monitor_test")
        monitorStudent = intent.getIntExtra("monitor_student", 0)

        /*if (monitorTest != null) {
            Toast.makeText(
                this,
                "monitor_test: " + monitorTest,
                Toast.LENGTH_SHORT
            ).show()
        }*/
        if (intent.getIntExtra("monitor_student", 0) == 1) {
            contentView.camera.setLifecycleOwner(this)
            contentView.camera.addCameraListener(Listener())
        } else {
            contentView.camera.visibility = View.GONE
        }

        progressDialog = ProgressDialog(this)
        progressDialog.setCancelable(false)
        progressDialog.isIndeterminate = true
        progressDialog.setMessage("Please wait...")
        contentView.linearLayout3.visibility = View.GONE
        userSelectedTime = intent.getLongExtra("duration", 0)
        mUserId = intent.getStringExtra("user_id") ?: ""
        mSchoolId = intent.getStringExtra("school_id") ?: ""
        accessToken = intent.getStringExtra("accessToken") ?: ""

        if (mUserId.isBlank()) {
            Toast.makeText(
                this,
                "User not initialised, you may need to logout and login again",
                Toast.LENGTH_SHORT
            ).show()
            finish()
        }

        contentView.viewPager.offscreenPageLimit = 4

        contentView.buttonSubmit.setOnClickListener {
            submitRoutine()
        }

        getQueries()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 498 && resultCode == Activity.RESULT_OK) {
            val p = data?.getIntExtra("position", -1)
            p?.let {
                if (p != -1) {
                    contentView.viewPager.currentItem = p
                }
            }
            fragmentManager.popBackStack()
        }
    }

    fun capturePictureSnapshot(qId: String) {
        if (contentView.camera.isTakingPicture) return
        if (contentView.camera.preview != Preview.GL_SURFACE) {
            return
        }
        mLastAnsweredQuestionId = qId
        contentView.camera.takePictureSnapshot()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        var valid = true
        for (grantResult in grantResults) {
            valid = valid && grantResult == PackageManager.PERMISSION_GRANTED
        }
        if (!valid) {
            Toast.makeText(this, "Tests require camera permission to work", Toast.LENGTH_SHORT)
                .show()
            finish()
            return
        }
        if (valid && !contentView.camera.isOpened) {
            contentView.camera.open()
        }
    }

    private fun getQueries() {
        progressDialog.show()


        val call = NetworkClient.create()
            .getOptionalTestQuestions(intent.getStringExtra("test_id"), accessToken)
        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        d1("response", response.body().toString());
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            val jsonArray = jsonObject.getJSONArray("data")
                            for (i in 0 until jsonArray.length()) {
                                val modelTestQuestion = ModelTestQuestion(false)
                                modelTestQuestion.questionId =
                                    jsonArray.getJSONObject(i).getString("id")
                                modelTestQuestion.question =
                                    jsonArray.getJSONObject(i).getString("question")
                                modelTestQuestion.optionA =
                                    jsonArray.getJSONObject(i).getString("option_a")
                                modelTestQuestion.optionB =
                                    jsonArray.getJSONObject(i).getString("option_b")
                                modelTestQuestion.optionC =
                                    jsonArray.getJSONObject(i).getString("option_c")
                                modelTestQuestion.optionD =
                                    jsonArray.getJSONObject(i).getString("option_d")
                                modelTestQuestion.answer =
                                    jsonArray.getJSONObject(i).getString("answer")

                                modelTestQuestion.marks =
                                    jsonArray.getJSONObject(i).optString("marks")

                                mQuestionsList.add(modelTestQuestion)
                            }
                            inItPager(mQuestionsList)
                        }

                    }
                    progressDialog.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressDialog.dismiss()
                Toast.makeText(
                    this@ActivityObjectiveTestRoom,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                ).show()
            }


        })
    }

    private fun getSignedUrls(fileToUpload: File) {
        progressDialog.show()
        progressDialog.setCancelable(false)

        val fileKEy =
            "flip/tests/test_${intent.getStringExtra("test_id")}/${mUserId}_${fileToUpload.name}"
        val call = NetworkClient.create().getSignedUrlForS3(fileKEy, accessToken)
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
                                    0, fileToUpload.length().toInt()
                                )
                            val upload = NetworkClient.create().uploadS3(signedUrl, requestFile)
                            upload.enqueue(object : Callback<String?> {
                                override fun onFailure(call: Call<String?>, t: Throwable) {
                                    progressDialog.dismiss()
                                    Toast.makeText(
                                        this@ActivityObjectiveTestRoom,
                                        "Not uploaded",
                                        Toast.LENGTH_SHORT
                                    ).show()
                                }

                                override fun onResponse(
                                    call: Call<String?>,
                                    response: Response<String?>
                                ) {
                                    progressDialog.dismiss()
                                    submitTests(fileKEy)
                                }
                            })
                        }

                    } else {
                        progressDialog.dismiss()
                    }
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressDialog.dismiss()
                Toast.makeText(
                    this@ActivityObjectiveTestRoom,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                ).show()
            }


        })
    }

    private fun submitTests(s3FileKey: String?) {
        progressDialog.show()

        val call = NetworkClient.create().saveTest(
            mUserId,
            intent.getStringExtra("test_id")!!,
            getQUestionCount().toString(),
            getCorrectAnswersCount().toString(),
            getAttemptedQuesCount().toString(),
            getUserSelectedAnswers(),
            getTimeSpent(),
            s3FileKey ?: " ",
            mSchoolId,
            accessToken
        )

        call.enqueue(object : Callback<String> {

            override fun onResponse(call: Call<String>?, response: Response<String>?) {
                response?.let {
                    if (response.isSuccessful) {
                        val jsonObject = JSONObject(response.body().toString())
                        if (jsonObject.has("status") && jsonObject.getString("status") == "success") {
                            Toast.makeText(
                                this@ActivityObjectiveTestRoom,
                                "Test Submitted",
                                Toast.LENGTH_SHORT
                            ).show()
                            finish()
                        }

                    }
                    progressDialog.dismiss()
                }
            }

            override fun onFailure(call: Call<String>?, t: Throwable?) {
                progressDialog.dismiss()
                Toast.makeText(
                    this@ActivityObjectiveTestRoom,
                    "There has been error, please try again",
                    Toast.LENGTH_SHORT
                ).show()
            }


        })
    }


    fun inItPager(data: MutableList<ModelTestQuestion>) {
        val adapter = AdapterSchoolTestRoom(fragmentManager, this, data)
        contentView.viewPager.adapter = adapter
        contentView.tabLayout.setupWithViewPager(contentView.viewPager)

        for (i in 0..contentView.tabLayout.tabCount) {
            contentView.tabLayout.getTabAt(i)?.customView = adapter.getTabView(i)
        }


        val v = contentView.tabLayout.getChildAt(0) as ViewGroup


        val yellowD = VectorDrawableCompat.create(resources, R.drawable.c_circle_white, theme)

        yellowD?.setColorFilter(
            ContextCompat.getColor(this, R.color.yellow),
            PorterDuff.Mode.SRC_ATOP
        )



        contentView.tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabReselected(tab: TabLayout.Tab?) {
                //Just return
            }

            override fun onTabUnselected(tab: TabLayout.Tab?) {
                val tabPosition = tab?.position

                if (mQuestionsList[tabPosition!!].userSelectedAnswer != -1) {
                    mQuestionsList[tabPosition].skipped = 0
                    val image =
                        contentView.tabLayout.getTabAt(tabPosition)?.customView?.findViewById<ImageView>(
                            R.id.imageView
                        )
                    image?.setColorFilter(
                        ContextCompat.getColor(
                            this@ActivityObjectiveTestRoom,
                            R.color.zm_green
                        )
                    )
                    image?.visibility = View.VISIBLE
                } else {
                    mQuestionsList[tabPosition].skipped = 1
                    val image =
                        contentView.tabLayout.getTabAt(tabPosition)?.customView?.findViewById<ImageView>(
                            R.id.imageView
                        )
                    image?.setColorFilter(
                        ContextCompat.getColor(
                            this@ActivityObjectiveTestRoom,
                            R.color.yellow
                        )
                    )
                    image?.visibility = View.VISIBLE
                }
            }

            override fun onTabSelected(tab: TabLayout.Tab?) {
                val image = tab?.customView?.findViewById<ImageView>(R.id.imageView)
                image?.visibility = View.INVISIBLE

            }
        })

        start()
    }


    fun start() {
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
                contentView.countDownTimer.text =
                    "${format.format(hours)}:${format.format(minutes)}:${format.format(seconds)}"

            }

            override fun onFinish() {
                contentView.countDownTimer.text = "Finished"
                //submit auto test after time is finished
                if (monitorTest != null && monitorTest == "1") {
                    //zipImageFiles()
                    createPdfFile()
                } else {
                    submitTests(" ")
                }
                /*supportFragmentManager.beginTransaction().add(R.id.frameLayout, FrgTestFinished())
                    .addToBackStack(null)
                    .commitAllowingStateLoss()*/
            }
        }.start()

    }

    fun submitRoutine() {
        val d = CustomAlertDialog(this, R.style.PurpleTheme)
        d.setCancelable(false)
        d.setTitle("Submit Test")
        d.setMessage("Are you sure you want to submit this test? You have attempted ${getAttemptedQuesCount()} questions.")
        d.positiveButton.setOnClickListener {
            d.dismiss()
            if (monitorTest != null && monitorTest == "1") {
                //zipImageFiles()
                createPdfFile()
            } else {
                submitTests(" ")
            }

        }

        d.negativeButton.setOnClickListener {
            d.dismiss()
        }
        d.show()
    }

    private fun createPdfFile() {
        progressDialog.show()
        progressDialog.setCancelable(false)
        doAsync {

            val submissionsDir =
                File(filesDir.absolutePath + "/test_${intent.getStringExtra("test_id")}")
            val files = submissionsDir.listFiles()
            if (files != null && files.isNotEmpty()) {
                val list = mutableListOf<String>()
                val dFile = File(
                    filesDir.absolutePath + "/test_${
                        intent.getStringExtra("test_id")
                    }_comp"
                )

                val document = PDDocument()
                var contentStream: PDPageContentStream? = null

                files.forEach {
                    val compressedFile =
                        SiliCompressor.with(this@ActivityObjectiveTestRoom).compress(
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
                val path = cacheDir.absolutePath + "/test_${intent.getStringExtra("test_id")}.pdf"
                document.save(path)
                document.close()
                val zipFileLocation = File(path)
                //val zipFileLocation = File(cacheDir.absolutePath + "/submissions/submissions_${intent.getStringExtra("test_id")}.zip")
                //ZipManager().zip(list.toTypedArray(), zipFileLocation.absolutePath)
                dFile.deleteRecursively()
                submissionsDir.deleteRecursively()
                runOnUiThread {
                    progressDialog.dismiss()
                    getSignedUrls(zipFileLocation)
                }
            } else {
                runOnUiThread {
                    toast("Failed to attach screenshots")
                    submitTests("")
                }
            }
        }
    }


    private fun zipImageFiles() {
        progressDialog.show()
        progressDialog.setCancelable(false)
        val imageCacheDir =
            File(filesDir.absolutePath + "/test_${intent.getStringExtra("test_id")}")
        val files = imageCacheDir.listFiles()
        if (files != null && files.isNotEmpty()) {
            val list = mutableListOf<String>()
            files.forEach {
                list.add(it.absolutePath)
            }
            val zipFileLocation =
                File(filesDir.absolutePath + "/test_${intent.getStringExtra("test_id")}.zip")
            ZipManager().zip(list.toTypedArray(), zipFileLocation.absolutePath)
            progressDialog.dismiss()
            getSignedUrls(zipFileLocation)
        } else {
            //toast("No answer found")
        }

    }

    fun getQuestionList(): ArrayList<ModelTestQuestion> {
        return mQuestionsList as ArrayList<ModelTestQuestion>
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

    fun getAttemptedQuesCount(): Int {
        var i = 0
        mQuestionsList.forEach {
            if (it.userSelectedAnswer != -1) {
                i += 1
            }
        }
        return i
    }

    fun getSkipped(): Int {
        var i = 0
        mQuestionsList.forEach {
            if (it.skipped == 1) {
                i += 1
            }
        }
        return i
    }

    fun getUnAttemptedQuesCount(): Int {
        var i = 0
        mQuestionsList.forEach {
            if (it.userSelectedAnswer == -1 && it.skipped == 0) {
                i += 1
            }
        }
        return i
    }

    fun getQUestionCount(): Int {
        return mQuestionsList.size
    }

    fun getClass(): String {
        return intent.getStringExtra("class")
    }

    fun getSubjectId(): String {
        return intent.getStringExtra("subjectId")
    }

    fun getTopics(): String {
        return intent.getStringExtra("topics")
    }

    fun getTestQuestionIds(): String {
        var s = ""
        mQuestionsList.forEach {
            s = s.plus("${it.questionId},")
        }
        return s.trim(',')
    }

    fun getUserSelectedAnswers(): String {
        val array = JSONArray()
        mQuestionsList.forEach {
            val obj = JSONObject()
            obj.put("q_id", it.questionId)
            if (it.userSelectedOption.isNotBlank()) {
                obj.put("selected_answer", it.userSelectedOption)
            } else if (it.skipped == 1) {
                obj.put("selected_answer", "skipped")
            } else {
                obj.put("selected_answer", "not_attempted")
            }
            array.put(obj)
        }
        return array.toString()
    }

    fun getCorrectAnswersCount(): Int {
        var i = 0
        mQuestionsList.forEach {
            if (it.userSelectedOption.equals(it.answer, true)) {
                i += 1
            }
        }
        return i
    }

    fun getTimeSpent(): String {
        val totalTime = userSelectedTime * 60000 + 1000
        val timeSpentMilli = totalTime - remainingTime

        val hours = ((timeSpentMilli / (1000 * 60 * 60)) % 24).toInt()
        val minutes = (timeSpentMilli / 60000).toInt()
        val seconds = (timeSpentMilli % 60000 / 1000).toInt()
        val format = NumberFormat.getNumberInstance()
        format.minimumIntegerDigits = 2
        return "${format.format(hours)}:${format.format(minutes)}:${format.format(seconds)}"
    }

    fun getTestDuration(): String {
        return intent.getLongExtra("duration", 0).toString()

    }

    //region Permissions
    inner class Listener : CameraListener() {
        override fun onCameraOpened(options: CameraOptions) {}

        override fun onPictureTaken(result: PictureResult) {
            super.onPictureTaken(result)
            try {
                val imageCacheDir =
                    File(filesDir.absolutePath + "/test_${intent.getStringExtra("test_id")}")
                if (!imageCacheDir.exists()) {
                    imageCacheDir.mkdir()
                }
                val mSelectedFile =
                    File(imageCacheDir.absolutePath + "/q_${mLastAnsweredQuestionId}.jpg")

                result.toFile(mSelectedFile, FileCallback {
                    d1("ok", "SAVED")
                })
            } catch (e: URISyntaxException) {
                e.printStackTrace()
            }
        }

    }

}
