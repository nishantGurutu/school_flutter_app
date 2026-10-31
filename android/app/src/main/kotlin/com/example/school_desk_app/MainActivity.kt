package com.school.app

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pendingAttachment: MethodChannel.Result? = null
    private val attachmentReader = Executors.newSingleThreadExecutor()
    private val attachmentRequestCode = 24571
    private val maxAttachmentBytes = 25 * 1024 * 1024

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "school_desk/chat_attachments").setMethodCallHandler { call, result ->
            if (call.method != "pick") { result.notImplemented(); return@setMethodCallHandler }
            if (pendingAttachment != null) { result.error("picker_busy", "A file picker is already open.", null); return@setMethodCallHandler }
            val kind = call.argument<String>("kind") ?: "any"
            val mime = when (kind) { "image" -> "image/*"; "video" -> "video/*"; "any" -> "*/*"; else -> { result.error("invalid_type", "Unsupported attachment picker.", null); return@setMethodCallHandler } }
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mime
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            pendingAttachment = result
            try { startActivityForResult(intent, attachmentRequestCode) }
            catch (e: Exception) { pendingAttachment = null; result.error("picker_unavailable", "No system file picker is available. Enable the Files app and retry.", null) }
        }
    }

    @Deprecated("Uses the Activity result bridge supported by FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != attachmentRequestCode) { super.onActivityResult(requestCode, resultCode, data); return }
        val result = pendingAttachment ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { pendingAttachment = null; result.success(null); return }
        attachmentReader.execute {
            try {
                var name = "attachment"
                var size: Long? = null
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                        if (nameIndex >= 0 && !cursor.isNull(nameIndex)) name = cursor.getString(nameIndex)
                        if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
                    }
                }
                require(size == null || size!! <= maxAttachmentBytes) { "Choose a file up to 25 MB." }
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    var count = input.read(buffer)
                    while (count != -1) {
                        require(output.size().toLong() + count <= maxAttachmentBytes) { "Choose a file up to 25 MB." }
                        output.write(buffer, 0, count)
                        count = input.read(buffer)
                    }
                    output.toByteArray()
                } ?: throw IllegalStateException("Unable to read the selected file. Download it to this device and retry.")
                require(bytes.isNotEmpty()) { "The selected file is empty." }
                val type = contentResolver.getType(uri) ?: "application/octet-stream"
                Handler(Looper.getMainLooper()).post {
                    if (pendingAttachment === result) { pendingAttachment = null; result.success(mapOf("name" to name, "bytes" to bytes, "mimeType" to type)) }
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    if (pendingAttachment === result) { pendingAttachment = null; result.error("file_unreadable", e.message ?: "Unable to read selected file. Please retry.", null) }
                }
            }
        }
    }

    override fun onDestroy() {
        pendingAttachment?.error("picker_closed", "File selection was interrupted. Please select the file again.", null)
        pendingAttachment = null
        attachmentReader.shutdownNow()
        super.onDestroy()
    }
}
