package com.example.voting_system

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
	private val reportChannel = "com.example.voting_system/reports"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, reportChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"savePdfToDownloads" -> {
						val fileName = call.argument<String>("fileName")
						val bytes = call.argument<ByteArray>("bytes")

						if (fileName.isNullOrBlank() || bytes == null) {
							result.error(
								"INVALID_ARGUMENTS",
								"fileName and bytes are required",
								null,
							)
							return@setMethodCallHandler
						}

						try {
							val savedPath = savePdfToDownloads(fileName, bytes)
							result.success(savedPath)
						} catch (exception: Exception) {
							result.error(
								"SAVE_FAILED",
								exception.message,
								null,
							)
						}
					}

					else -> result.notImplemented()
				}
			}
	}

	@Throws(IOException::class)
	private fun savePdfToDownloads(fileName: String, bytes: ByteArray): String {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			saveWithMediaStore(fileName, bytes)
		} else {
			saveToLegacyDownloads(fileName, bytes)
		}
	}

	@Throws(IOException::class)
	private fun saveWithMediaStore(fileName: String, bytes: ByteArray): String {
		val resolver = applicationContext.contentResolver
		val values = ContentValues().apply {
			put(MediaStore.Downloads.DISPLAY_NAME, fileName)
			put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
			put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
			put(MediaStore.Downloads.IS_PENDING, 1)
		}

		val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
		val itemUri = resolver.insert(collection, values)
			?: throw IOException("Unable to create download entry")

		resolver.openOutputStream(itemUri)?.use { outputStream ->
			outputStream.write(bytes)
			outputStream.flush()
		} ?: throw IOException("Unable to open output stream")

		values.clear()
		values.put(MediaStore.Downloads.IS_PENDING, 0)
		resolver.update(itemUri, values, null, null)

		return "Downloads/$fileName"
	}

	@Throws(IOException::class)
	private fun saveToLegacyDownloads(fileName: String, bytes: ByteArray): String {
		val downloadsDirectory =
			Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)

		if (!downloadsDirectory.exists() && !downloadsDirectory.mkdirs()) {
			throw IOException("Unable to access Downloads directory")
		}

		val outputFile = File(downloadsDirectory, fileName)
		FileOutputStream(outputFile).use { outputStream ->
			outputStream.write(bytes)
			outputStream.flush()
		}

		MediaScannerConnection.scanFile(
			applicationContext,
			arrayOf(outputFile.absolutePath),
			arrayOf("application/pdf"),
			null,
		)

		return outputFile.absolutePath
	}
}
