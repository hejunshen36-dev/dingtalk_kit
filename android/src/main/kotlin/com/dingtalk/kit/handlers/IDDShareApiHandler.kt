package com.dingtalk.kit.handlers

import android.content.Context
import android.content.Intent
import android.util.Log
import com.android.dingtalk.share.ddsharemodule.DDShareApiFactory
import com.android.dingtalk.share.ddsharemodule.DDShareConfiguration
import com.android.dingtalk.share.ddsharemodule.IDDAPIEventHandler
import com.android.dingtalk.share.ddsharemodule.IDDShareApi
import com.android.dingtalk.share.ddsharemodule.message.*
import com.dingtalk.kit.constant.CallResult
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

object IDDShareApiHandler {
    private const val CALLBACK_PREFERENCES = "dingtalk_kit"
    // Read only when migrating a pre-rename installation; new registrations use the new key.
    private const val LEGACY_CALLBACK_PREFERENCES = "flutter_dingtalk_sdk"
    private const val CALLBACK_APP_ID = "registered_app_id"
    var  iddShareApi : IDDShareApi? = null

    private var context : Context? = null

    fun setRegister(register:Context?){
        this.context = register
    }

    fun openAPIVersion(call: MethodCall, result: MethodChannel.Result) {
        val req = SendAuth.Req()
        result.success("${req.supportVersion}")
    }

    fun registerApp(call: MethodCall, result: MethodChannel.Result) {
        val appId: String? = call.argument("appId")
        if (iddShareApi != null){
            result.success(true)
            return
        }
        if (appId.isNullOrBlank()){
            result.error(CallResult.Result_APPID_NULL,"not set AppId",null)
            return
        }
        // This channel integrates standard DingTalk. Pin its package so the SDK
        // does not probe AliDing or dispatch an implicit cross-app intent.
        DDShareConfiguration.get()
            .setTargetPackageName("com.alibaba.android.rimet")
            .setForceTarget(true)
        iddShareApi = DDShareApiFactory.createDDShareApi(context,appId,true)
        // Only the public app ID is persisted; callback payloads/auth codes are not.
        context?.getSharedPreferences(CALLBACK_PREFERENCES, Context.MODE_PRIVATE)
            ?.edit()?.putString(CALLBACK_APP_ID, appId)?.apply()
        result.success(true)
    }

    fun callbackApi(context: Context): IDDShareApi? {
        iddShareApi?.let { return it }
        val preferences = context.getSharedPreferences(CALLBACK_PREFERENCES, Context.MODE_PRIVATE)
        var appId = preferences.getString(CALLBACK_APP_ID, null)
        if (appId.isNullOrBlank()) {
            appId = context.getSharedPreferences(LEGACY_CALLBACK_PREFERENCES, Context.MODE_PRIVATE)
                .getString(CALLBACK_APP_ID, null)
            if (appId.isNullOrBlank()) return null
            preferences.edit().putString(CALLBACK_APP_ID, appId).apply()
        }
        // Match the demo: initialize a callback-local API after process recreation.
        // Never retain the callback Activity in the sender singleton.
        return DDShareApiFactory.createDDShareApi(context, appId, false)
    }

    fun unregisterApp(result: MethodChannel.Result){
        iddShareApi?.unregisterApp()
        result.success(true)
    }

    fun isDDAppInstalled(result: MethodChannel.Result) {
        if (iddShareApi == null)
            result.error(CallResult.RESULT_API_NULL, "DingDing Api Not Registered", null)
        else
            result.success(iddShareApi!!.isDDAppInstalled)
    }

    fun isDingTalkSupportSSO(result: MethodChannel.Result) {
        val req = SendAuth.Req()
        if (iddShareApi == null)
            result.error(CallResult.RESULT_API_NULL, "DingDing Api Not Registered", null)
        else
            result.success( !(req.supportVersion > iddShareApi!!.ddSupportAPI) )
    }

    fun openDDApp(result: MethodChannel.Result) {
        if (iddShareApi == null)
            result.error(CallResult.RESULT_API_NULL, "DingDing Api Not Registered", null)
        else
            result.success(iddShareApi!!.openDDApp())
    }

    fun sendAuth(call: MethodCall, result: MethodChannel.Result) {
        val req = SendAuth.Req()
        req.scope = SendAuth.Req.SNS_LOGIN;
        req.state = call.argument<String>("state") ?: "state";
        if (iddShareApi == null) {
            result.error(CallResult.RESULT_API_NULL, "DingDing Api Not Registered", null)
        } else if (!iddShareApi!!.isDDAppInstalled) {
            result.error(CallResult.RESULT_NOT_INSTALLED, "DingDing not installed", null)
        } else if (req.supportVersion > iddShareApi!!.ddSupportAPI) {
            //钉钉版本过低，不支持登录授权
            result.error(CallResult.RESULT_VERSION_IS_TOO_LOW, "DingDing version is too low", null)
        } else {
            result.success(iddShareApi?.sendReq(req))
        }
    }

    /**
     * 分享文本消息
     */
    fun sendTextMessage(args: Map<String?, Any?>, result: MethodChannel.Result) {
        val text = args["text"] as String?
        val isSendDing = args["isSendDing"] as Boolean

        //初始化一个DDTextMessage对象
        val textObject = DDTextMessage()
        textObject.mText = text

        //用DDTextMessage对象初始化一个DDMediaMessage对象
        val mediaMessage = DDMediaMessage()
        mediaMessage.mMediaObject = textObject

        //构造一个Req
        val req = SendMessageToDD.Req()
        req.mMediaMessage = mediaMessage

        //调用api接口发送消息到钉钉
        sendShareRequest(req, isSendDing, result)
    }

    /**
     * 分享网页消息
     */
    fun sendWebPageMessage(args: Map<String?, Any?>, result: MethodChannel.Result) {
        val mUrl = args["url"] as String?
        val isSendDing = args["isSendDing"] as Boolean

        //初始化一个DDWebpageMessage并填充网页链接地址
        val webPageObject = DDWebpageMessage()
        webPageObject.mUrl = mUrl

        //构造一个DDMediaMessage对象
        val webMessage = DDMediaMessage()
        webMessage.mMediaObject = webPageObject
        webMessage.mTitle = args["title"] as String?
        webMessage.mContent = args["content"] as String?
        webMessage.mThumbUrl = args["thumbUrl"] as String?
        // 网页分享的缩略图也可以使用bitmap形式传输
//         webMessage.setThumbImage(BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher));

        //构造一个Req
        val webReq = SendMessageToDD.Req()
        webReq.mMediaMessage = webMessage
        //        webReq.transaction = buildTransaction("webpage");

        // 调用 SDK 接口将网页消息分享到钉钉。
        sendShareRequest(webReq, isSendDing, result)
    }

    /**
     * 分享图片消息
     */
    fun sendImageMessage(args: Map<String?, Any?>, result: MethodChannel.Result) {
        val isSendDing = args["isSendDing"] as Boolean
        //初始化一个DDImageMessage
        val imageObject = DDImageMessage()


        //url图片
        if (args["picUrl"] != null) {
            val picUrl = args["picUrl"] as String?
            imageObject.mImageUrl = picUrl
        } else if (args["picPath"] != null) {
            //本地图片
            val picPath = args["picPath"] as String?
            val file = File(picPath)
            if (!file.exists()) {
                result.error("picPath error", "Invalid local image path", null)
                return
            } else {
                imageObject.mImagePath = picPath
            }
        } else {
            Log.d("DingtalkKit", "无图片来源")
            result.error("Image error", "请传输图片来源", null)
            return
        }


        //构造一个mMediaObject对象
        val mediaMessage = DDMediaMessage()
        mediaMessage.mMediaObject = imageObject

        //构造一个Req
        val req = SendMessageToDD.Req()
        req.mMediaMessage = mediaMessage
        //        req.transaction = buildTransaction("image");

        // 调用 SDK 接口将图片消息分享到钉钉。
        sendShareRequest(req, isSendDing, result)
    }

    // Complete the channel with dispatch acceptance; onResp is a separate event.
    private fun sendShareRequest(
        req: SendMessageToDD.Req,
        isSendDing: Boolean,
        result: MethodChannel.Result
    ) {
        val api = iddShareApi
        if (api == null) {
            result.error(CallResult.RESULT_API_NULL, "DingDing Api Not Registered", null)
            return
        }
        val accepted = try {
            if (isSendDing) api.sendReqToDing(req) else api.sendReq(req)
        } catch (_: Exception) {
            result.error("ShareError", "Unable to dispatch DingTalk share", null)
            return
        }
        result.success(accepted)
    }

    fun handleIntent(var1: Intent?, var2: IDDAPIEventHandler?) {
        try {
            iddShareApi!!.handleIntent(var1, var2)
        } catch (e: Exception) {
            e.printStackTrace()
            Log.d("DingtalkKit", "e===========>$e")
        }
    }

}
