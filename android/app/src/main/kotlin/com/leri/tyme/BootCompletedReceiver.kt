package com.leri.tyme

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent


/**
 * @author DingWei
 * @version 2023/12/13 13:33
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action ||
            Intent.ACTION_MY_PACKAGE_REPLACED == intent.action ||
            Intent.ACTION_LOCKED_BOOT_COMPLETED == intent.action
        ) {
            val launchIntent = Intent(context, MainActivity::class.java)
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launchIntent)
        }
    }
}