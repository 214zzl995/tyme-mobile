package com.leri.tyme

import android.content.ContentResolver
import android.content.Context
import android.media.RingtoneManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val FLUTTER_ANDROID_LOG_CHANNEL = "leri.dev/tyme.log"
        const val FLUTTER_ANDROID_DRAWABLE_CHANNEL = "leri.dev/tyme.drawable"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, FLUTTER_ANDROID_DRAWABLE_CHANNEL
        ).setMethodCallHandler { call, result ->
            if ("drawableToUri" == call.method) {
                val resourceId = when (call.arguments) {
                    is String -> {
                        val resourceName = call.arguments as String
                        val field = R.drawable::class.java.getField(resourceName)
                        field.getInt(null)
                    }

                    else -> 0
                }
                result.success(resourceToUriString(this@MainActivity.applicationContext, resourceId))
            }
            if ("getAlarmUri" == call.method) {
                result.success(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM).toString())
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FLUTTER_ANDROID_LOG_CHANNEL
        ).setMethodCallHandler { call, result ->
                val tag: String = call.argument("tag") ?: "LogUtils"
                val message: String = call.argument("msg") ?: "unknown log message"
                when (call.method) {
                    "logD" -> Log.d(tag, message)
                    "logE" -> Log.e(tag, message)
                }
                result.success(null)
            }
    }

    private fun resourceToUriString(context: Context, resId: Int): String {
        return (ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + context.resources.getResourcePackageName(resId) + "/" + context.resources.getResourceTypeName(
            resId
        ) + "/" + context.resources.getResourceEntryName(resId))
    }
}
