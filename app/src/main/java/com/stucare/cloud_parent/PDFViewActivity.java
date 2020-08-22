package com.stucare.cloud_parent;

import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.databinding.DataBindingUtil;


import com.stucare.cloud_parent.databinding.PdfViewerBinding;

import java.io.File;

public class PDFViewActivity extends AppCompatActivity {

    private static final String AUTHORITY =
            BuildConfig.APPLICATION_ID + ".fileprovider";
    private PdfViewerBinding mContentView;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContentView = DataBindingUtil.setContentView(this, R.layout.pdf_viewer);
        displayFromUri();
    }

    private void displayFromUri() {
        File file = new File(getIntent().getStringExtra("file"));

        mContentView.pdfView.fromFile(file)
                .defaultPage(0)
                .enableAnnotationRendering(true)
                .spacing(10)
                .load();
    }


    public String getFileName(Uri uri) {
        String result = null;
        if (uri.getScheme().equals("content")) {
            Cursor cursor = getContentResolver().query(uri, null, null, null, null);
            try {
                if (cursor != null && cursor.moveToFirst()) {
                    result = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
                }
            } finally {
                if (cursor != null) {
                    cursor.close();
                }
            }
        }
        if (result == null) {
            result = uri.getLastPathSegment();
        }
        return result;
    }
}
