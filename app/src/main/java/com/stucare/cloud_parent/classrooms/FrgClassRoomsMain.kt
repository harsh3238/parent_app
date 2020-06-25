package com.stucare.cloud_parent.classrooms
import android.app.ProgressDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.databinding.DataBindingUtil
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.stucare.cloud_parent.R
import com.stucare.cloud_parent.databinding.ClassRoomMainBinding
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response


class FrgClassRoomsMain : Fragment() {

  //lateinit var networkClient: NetworkClient

  private lateinit var progressDialog: ProgressDialog

  lateinit var contentView: ClassRoomMainBinding


  override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
    contentView = DataBindingUtil.inflate<ClassRoomMainBinding>(inflater,
        R.layout.class_room_main, container, false)
    return contentView.root
  }

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    progressDialog = ProgressDialog(activity)
    progressDialog.setCancelable(false)
    progressDialog.isIndeterminate = true
    progressDialog.setMessage("Please wait...")

    contentView.recyclerView.layoutManager = LinearLayoutManager(activity)

    getLiveVideos()
    super.onViewCreated(view, savedInstanceState)
  }

  fun getLiveVideos() {
    /*progressDialog.show()
    val call = networkClient.getLiveClasses((activity?.applicationContext as MyApplication).usersData.id, "0")
    call.enqueue(object : Callback<String> {
      override fun onResponse(call: Call<String>?, response: Response<String>?) {
        if (response != null && response.isSuccessful) {
          MyLog.Log(this@FrgClassRoomsMain, response.body().toString().trim(), "getLiveVideos onResponse")
          val responeObject = JSONObject(response.body().toString().trim())
          if (responeObject.has("status") && responeObject.getString("status") == "success") {
            val dataObject = responeObject.getJSONArray("data")
            contentView.recyclerView.adapter = AdapterClassRoom(activity as ActivityClassesTabs, dataObject) {
              markAttendance(it)
            }
          }
        }
        progressDialog.dismiss()

      }

      override fun onFailure(call: Call<String>?, t: Throwable?) {
        progressDialog.dismiss()
        MyLog.Log(this@FrgClassRoomsMain, t?.localizedMessage
            ?: "", "getLiveVideos onFailure")
      }
    })*/
  }

  fun markAttendance(classId: String) {
    /*val call = networkClient.markLiveClassAttendance((activity?.applicationContext as MyApplication).usersData.id, classId)
    call.enqueue(object : Callback<String> {
      override fun onResponse(call: Call<String>?, response: Response<String>?) {
      }

      override fun onFailure(call: Call<String>?, t: Throwable?) {
      }
    })*/
  }
}