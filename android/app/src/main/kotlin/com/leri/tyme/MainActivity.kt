package com.leri.tyme

import android.content.ContentResolver
import android.content.Context
import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "leri.dev/tyme").setMethodCallHandler { call, result ->
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
    }

    private fun resourceToUriString(context: Context, resId: Int): String {
        return (ContentResolver.SCHEME_ANDROID_RESOURCE + "://"
                + context.resources.getResourcePackageName(resId)
                + "/"
                + context.resources.getResourceTypeName(resId)
                + "/"
                + context.resources.getResourceEntryName(resId))
    }
}
