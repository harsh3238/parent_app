package com.stucare.cloud_parent

import android.app.Dialog
import android.content.Context
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import androidx.core.content.ContextCompat
import com.squareup.picasso.Picasso
import java.io.File


/**
 * Author: Ashish Walia(ashishwalia.me)
 */
class DialogPhotoViewer(val mContext: Context, themeResId: Int, val imageUrl: String) :
    Dialog(mContext, themeResId) {

    lateinit var mContentView: View

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window?.setBackgroundDrawable(
             ColorDrawable(
                 ContextCompat.getColor(
                     mContext!!,
                     R.color.zm_black
                 )
             )
         )
        mContentView =
            LayoutInflater.from(mContext).inflate(R.layout.dialog_photo_viewer, null, false)
        setContentView(mContentView)

        val imageView = mContentView.findViewById<ImageView>(R.id.imageView)
        if(imageUrl.startsWith("http")){
            Picasso.get().load(imageUrl).into(imageView)
        }else{
            val f = File(imageUrl)
            Picasso.get().load(f).fit().centerInside().into(imageView)
        }

    }
}