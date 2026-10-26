package com.dingtalk.kit.ddshare

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.android.dingtalk.share.ddsharemodule.IDDAPIEventHandler
import com.android.dingtalk.share.ddsharemodule.message.BaseReq
import com.android.dingtalk.share.ddsharemodule.message.BaseResp
import com.dingtalk.kit.handlers.IDDShareApiHandler
import com.dingtalk.kit.handlers.IDDShareResponseHandler

open class DDShareActivity : Activity(), IDDAPIEventHandler {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleCallback(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleCallback(intent)
    }

    private fun handleCallback(intent: Intent?) {
        try {
            val handled = intent != null &&
                IDDShareApiHandler.callbackApi(this)?.handleIntent(intent, this) == true
            if (!handled) {
                finish()
            }
        } catch (e: Exception) {
            // This Activity is exported. Do not log callback extras or auth codes.
            Log.w("DDShareActivity", "Unable to handle DingTalk callback: ${e.javaClass.simpleName}")
            finish()
        }
    }

    override fun onResp(response: BaseResp?) {
        try {
            if (response != null) {
                IDDShareResponseHandler.handleResponse(response)
            }
        } finally {
            if (response != null) {
                returnToHostApp()
            }
            finish()
        }
    }

    private fun returnToHostApp() {
        try {
            // The host may use singleInstance and live in a different task.
            // Finishing this callback alone would reveal DingTalk underneath it.
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(launchIntent)
        } catch (e: Exception) {
            Log.w("DDShareActivity", "Unable to return to host app: ${e.javaClass.simpleName}")
        }
    }

    override fun onReq(request: BaseReq?) {
        finish()
    }
}
