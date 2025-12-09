package com.example.flutter_image_crop

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "native_image_picker"
    private val PERMISSION_REQUEST = 1001
    private val PICK_IMAGE = 1002
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> {
                        resultCallback = result
                        checkPermissionAndPick()
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun checkPermissionAndPick() {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            openPicker()
        } else {
            ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            openPicker()
        } else {
            resultCallback?.error("PERMISSION_DENIED", "Permission denied", null)
            resultCallback = null
        }
    }

    private fun openPicker() {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(intent, PICK_IMAGE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PICK_IMAGE && resultCallback != null) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    val filePath = copyToInternalStorage(uri)
                    resultCallback?.success(filePath)
                } else {
                    resultCallback?.error("NO_URI", "No URI returned", null)
                }
            } else {
                resultCallback?.error("CANCELLED", "User cancelled", null)
            }
            resultCallback = null
        }
    }

    private fun copyToInternalStorage(uri: Uri): String {
        // Get file name
        var fileName = "image_${System.currentTimeMillis()}.jpg"
        val cursor = contentResolver.query(uri, null, null, null, null)

        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    val name = it.getString(nameIndex)
                    if (name != null && name.isNotEmpty()) {
                        fileName = name
                    }
                }
            }
        }
        cursor?.close()

        // Create file in app's internal storage
        val internalDir = filesDir
        val outputFile = File(internalDir, fileName)

        // Copy content
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outputFile).use { output ->
                input.copyTo(output)
            }
        }

        return outputFile.absolutePath
    }
}