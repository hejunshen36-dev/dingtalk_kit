import 'dart:async';

import 'package:flutter/services.dart';
import 'response/dingtalk_response.dart';

/// 钉钉原生能力入口，对应 dingtalk_kit 平台通道。
class DingtalkKit {
  // Android、iOS、OHOS 必须使用同一通道名。
  static MethodChannel _channel = const MethodChannel('dingtalk_kit')
    ..setMethodCallHandler(_handleMethodCall);

  /// 向订阅方广播原生分享和授权响应。
  static StreamController<DingtalkResponse> _responseController =
      new StreamController.broadcast();

  /// 原生响应流；调用方应在不再需要时取消订阅。
  static Stream<DingtalkResponse> get responseStream =>
      _responseController.stream;

  /// iOS 返回 openAPIVersion；Android 返回授权请求所需的协议版本值。
  /// OHOS 当前返回空字符串，不应跨平台直接比较该结果。
  static Future<String> openAPIVersion() async {
    final String version = await _channel.invokeMethod('openAPIVersion');
    return version;
  }

  /// 注册钉钉 App ID；iOS 的 [iosBundleId] 必须与宿主 Bundle ID 一致。
  static Future<bool> registerApp(String appId, String iosBundleId) async {
    return await _channel
        .invokeMethod('registerApp', {"appId": appId, "bundleId": iosBundleId});
  }

  /// 检查是否安装钉钉；Android/OHOS 对应 SDK 的 isDDAppInstalled。
  /// 异常时返回 false。
  static Future<bool> isDingTalkInstalled() async {
    bool result = false;
    try {
      result = await _channel.invokeMethod('isDingTalkInstalled');
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 查询是否支持 SSO；OHOS 当前返回 false。
  static Future<bool> isDingTalkSupportSSO() async {
    bool result = false;
    try {
      result = await _channel.invokeMethod('isDingTalkSupportSSO');
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 请求打开钉钉；Android/OHOS 对应 openDDApp，iOS 使用 completion 回传结果。
  static Future<bool> openDingTalk() async {
    bool result = false;
    try {
      result = await _channel.invokeMethod('openDingTalk');
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 请求钉钉授权；授权码通过 [responseStream] 返回。
  /// 返回值不代表登录完成；OHOS 当前不支持授权并返回 false。
  static Future<bool> sendAuth(String state) async {
    bool result = false;
    try {
      result = await _channel.invokeMethod('sendAuth', {"state": "$state"});
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 分享文本；true 仅表示 SDK 接受派发，不表示用户已发送。
  static Future<bool> sendTextMessage(String text,
      {bool isSendDing = false}) async {
    bool result = false;
    try {
      result = await _channel.invokeMethod(
          'sendTextMessage', {"text": "$text", "isSendDing": isSendDing});
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 分享网页链接；true 仅表示 SDK 接受派发。
  static Future<bool> sendWebPageMessage(String url,
      {bool isSendDing = false,
      required String title,
      required String content,
      required String thumbUrl}) async {
    bool result = false;
    try {
      result = await _channel.invokeMethod('sendWebPageMessage', {
        "url": url,
        "isSendDing": isSendDing,
        'title': title,
        'content': content,
        'thumbUrl': thumbUrl
      });
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 分享图片；iOS 使用 [picUrl]，OHOS 仅接受本地路径或 file URI。
  /// 至少提供 [picUrl] 或 [picPath]；true 仅表示 SDK 接受派发。
  static Future<bool> sendImageMessage(
      {bool isSendDing = false, String? picUrl, String? picPath}) async {
    // Dart 层只检查是否提供来源，具体格式由各平台验证。
    if (picUrl == null && picPath == null) {
      return false;
    }
    bool result = false;
    try {
      result = await _channel.invokeMethod('sendImageMessage', {
        "picUrl": picUrl,
        "isSendDing": isSendDing,
        'picPath': picPath,
      });
    } catch (e) {
      print(e);
    }
    return result;
  }

  /// 将原生方法回调映射为响应对象并广播。
  static Future<dynamic> _handleMethodCall(MethodCall methodCall) {
    print('[DingtalkKit] response: ${methodCall.method}');
    var response =
        DingtalkResponse.create(methodCall.method, methodCall.arguments);
    _responseController.add(response);
    return Future.value(true);
  }
}
