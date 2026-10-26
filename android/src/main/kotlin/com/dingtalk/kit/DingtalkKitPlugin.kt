package com.dingtalk.kit

import androidx.annotation.NonNull
import com.dingtalk.kit.constant.Methods
import com.dingtalk.kit.handlers.IDDShareApiHandler
import com.dingtalk.kit.handlers.IDDShareResponseHandler

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Registers DingTalk handlers on the dingtalk_kit channel. */
class DingtalkKitPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dingtalk_kit")
    channel.setMethodCallHandler(this)
    IDDShareResponseHandler.setMethodChannel(channel)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method){
      Methods.OPEN_API_VERSION -> {
        IDDShareApiHandler.openAPIVersion(call,result)
      }
      Methods.REGISTER_APP -> {
        IDDShareApiHandler.registerApp(call,result)
      }
      Methods.UNREGISTER_APP -> {
        IDDShareApiHandler.unregisterApp(result)
      }
      Methods.IS_DINGTALK_INSTALLED -> {
        IDDShareApiHandler.isDDAppInstalled(result)
      }
      Methods.IS_DINGTALK_SUPPORT_SSO -> {
        IDDShareApiHandler.isDingTalkSupportSSO(result)
      }
      Methods.OPEN_DINGTALK -> {
        IDDShareApiHandler.openDDApp(result)
      }
      Methods.SEND_AUTH -> {
        IDDShareApiHandler.sendAuth(call,result)
      }
      Methods.SEND_TEXT_MESSAGE -> {
        IDDShareApiHandler.sendTextMessage(call.arguments as Map<String?, Any?>,result)
      }
      Methods.SEND_IMAGE_MESSAGE -> {
        IDDShareApiHandler.sendImageMessage(call.arguments as Map<String?, Any?>,result)
      }
      Methods.SEND_WEB_PAGE_MESSAGE -> {
        IDDShareApiHandler.sendWebPageMessage(call.arguments as Map<String?, Any?>,result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    IDDShareApiHandler.setRegister(null)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    IDDShareApiHandler.setRegister(binding.activity)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    IDDShareApiHandler.setRegister(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    IDDShareApiHandler.setRegister(null)
  }
}
