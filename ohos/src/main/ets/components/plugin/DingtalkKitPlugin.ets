import {
  AbilityAware,
  AbilityPluginBinding,
  Any,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  NewWantListener,
} from '@ohos/flutter_ohos';
import {
  DDShareApi,
  IDDShareApi,
  IDDAPIEventHandler,
  BaseReq,
  BaseResp,
  ErrCode,
  SendMessageToDD,
  DDMediaMessage,
  DDTextMessage,
  DDWebPageMessage,
  DDImageMessage,
} from '@dingtalk/ddsharesdk';
import { AbilityConstant, common, Want } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';

const CHANNEL_NAME = "dingtalk_kit";

/// 回调键名，对齐 dingtalk_response.dart：errCode / errStr / mTransaction / type
const KEY_ERR_CODE = "errCode";
const KEY_ERR_STR = "errStr";
const KEY_TRANSACTION = "mTransaction";
const KEY_TYPE = "type";

/**
 * DingtalkKitPlugin —— 钉钉分享 OHOS 实现。
 *
 * 与 Android(DingtalkKitPlugin.kt)/iOS(ApiHandler.m) 共用同一套 MethodChannel("dingtalk_kit")
 * 与 method 名，供 Dart 层 DingtalkKit(lib/dingtalk_kit.dart) 调用。
 *
 * 基于钉钉官方鸿蒙 SDK @dingtalk/ddsharesdk 实现文本 / 图片 / 网页链接分享。
 * 分享结果经钉钉回跳由 onNewWant -> handleWant 解析，通过 onShareResponse 回传 Dart。
 */
export default class DingtalkKitPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware, NewWantListener {
  private channel: MethodChannel | null = null;
  private binding: AbilityPluginBinding | null = null;
  private iddApi: IDDShareApi | null = null;

  /// 钉钉回跳结果处理器
  private eventHandler: IDDAPIEventHandler = {
    onReq: (req: BaseReq): void => {
      // 宿主作为被分享方时的请求回调，本场景（主动分享）无需处理。
    },
    onResp: (resp: BaseResp): void => {
      this.sendShareResponse(resp.mErrCode, resp.mErrStr ?? "", resp.getType());
    },
  };

  getUniqueClassName(): string {
    return "DingtalkKitPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.binding = binding;
    binding.addOnNewWantListener(this);
  }

  onDetachedFromAbility(): void {
    if (this.binding != null) {
      this.binding.removeOnNewWantListener(this);
    }
    this.binding = null;
  }

  /// 钉钉分享完成后回跳本应用，结果通过 want 携带。
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    this.iddApi?.handleWant(want, this.eventHandler);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "registerApp":
        this.registerApp(call, result);
        break;
      case "isDingTalkInstalled":
        result.success(this.iddApi?.isDDAppInstalled() ?? false);
        break;
      case "openDingTalk":
        this.openDDApp(result);
        break;
      case "sendTextMessage":
        this.sendTextMessage(call, result);
        break;
      case "sendWebPageMessage":
        this.sendWebPageMessage(call, result);
        break;
      case "sendImageMessage":
        this.sendImageMessage(call, result);
        break;
      // —— 以下能力 OHOS SDK 未提供，返回安全默认值 ——
      case "openAPIVersion":
        result.success("");
        break;
      case "isDingTalkSupportSSO":
        result.success(false);
        break;
      case "sendAuth":
        // 钉钉鸿蒙分享 SDK 不含授权登录能力
        result.success(false);
        break;
      case "unregisterApp":
        this.iddApi = null;
        result.success(true);
        break;
      default:
        result.notImplemented();
    }
  }

  private getContext(): common.UIAbilityContext | null {
    return this.binding?.getAbility().context ?? null;
  }

  private registerApp(call: MethodCall, result: MethodResult): void {
    const appId: string = call.argument("appId") as string;
    if (appId == null || appId.length == 0) {
      result.error("appId error", "appId is empty", null);
      return;
    }
    this.iddApi = DDShareApi.getInstance(appId);
    result.success(true);
  }

  private openDDApp(result: MethodResult): void {
    const context = this.getContext();
    if (this.iddApi == null || context == null) {
      result.success(false);
      return;
    }
    try {
      Promise.resolve(this.iddApi.openDDApp(context)).then((ok: boolean) => {
        result.success(ok);
      }).catch(() => {
        result.error("OpenError", "Unable to open DingTalk", null);
      });
    } catch (_) {
      result.error("OpenError", "Unable to open DingTalk", null);
    }
  }

  /// 发送请求统一出口：sendReq 返回 boolean | Promise<boolean>，统一按 Promise 处理。
  private sendReq(req: BaseReq, result: MethodResult): void {
    const context = this.getContext();
    if (this.iddApi == null || context == null) {
      result.error("api error", "DingDing Api Not Registered", null);
      return;
    }
    try {
      Promise.resolve(this.iddApi.sendReq(context, req)).then((ok: boolean) => {
        result.success(ok);
      }).catch(() => {
        result.error("ShareError", "Unable to dispatch DingTalk share", null);
      });
    } catch (_) {
      result.error("ShareError", "Unable to dispatch DingTalk share", null);
    }
  }

  /// 文本分享
  private sendTextMessage(call: MethodCall, result: MethodResult): void {
    const text: string = call.argument("text") as string;

    const textObject = new DDTextMessage();
    textObject.mText = text;

    const mediaMessage = new DDMediaMessage();
    mediaMessage.mMediaMessageObject = textObject;

    const req = new SendMessageToDD.Req();
    req.mMediaMessage = mediaMessage;
    this.sendReq(req, result);
  }

  /// 网页链接分享（标题 / 描述 / 缩略图）
  private sendWebPageMessage(call: MethodCall, result: MethodResult): void {
    const url: string = call.argument("url") as string;
    const title: string = call.argument("title") as string;
    const content: string = call.argument("content") as string;
    const thumbUrl: string = call.argument("thumbUrl") as string;

    const webObject = new DDWebPageMessage();
    webObject.mUrl = url;

    const mediaMessage = new DDMediaMessage();
    mediaMessage.mMediaMessageObject = webObject;
    mediaMessage.mTitle = title;
    mediaMessage.mContent = content;
    mediaMessage.mThumbUrl = thumbUrl;

    const req = new SendMessageToDD.Req();
    req.mMediaMessage = mediaMessage;
    this.sendReq(req, result);
  }

  /// 鸿蒙 SDK 只支持本地 URI；调用方需先将远程图片下载为 picPath。
  private sendImageMessage(call: MethodCall, result: MethodResult): void {
    const picPath: string | null = call.argument("picPath") as string;
    const picUrl: string | null = call.argument("picUrl") as string;
    const imageUri: string | null = (picPath != null && picPath.length > 0) ? picPath : picUrl;
    if (imageUri == null || imageUri.length == 0) {
      result.error("Image error", "请传输图片来源", null);
      return;
    }

    if (!imageUri.startsWith("/") && !imageUri.startsWith("file://")) {
      result.error("Image error", "DingTalk on OHOS requires a local image", null);
      return;
    }
    const imageObject = new DDImageMessage();
    try {
      imageObject.mImageUri = imageUri.startsWith("file://") ? imageUri : fileUri.getUriFromPath(imageUri);
    } catch (_) {
      result.error("Image error", "Invalid local image path", null);
      return;
    }

    const mediaMessage = new DDMediaMessage();
    mediaMessage.mMediaMessageObject = imageObject;

    const req = new SendMessageToDD.Req();
    req.mMediaMessage = mediaMessage;
    this.sendReq(req, result);
  }

  /**
   * 将分享结果回传 Dart，对应 Dart 端 _handleMethodCall 的 "onShareResponse"。
   * 结构对齐 dingtalk_response.dart 的 DingtalkShareResponse.fromMap。
   */
  private sendShareResponse(errCode: ErrCode, errStr: string, type: number): void {
    const resp: Map<string, Any> = new Map();
    resp.set(KEY_ERR_CODE, errCode);
    resp.set(KEY_ERR_STR, errStr);
    resp.set(KEY_TRANSACTION, "");
    resp.set(KEY_TYPE, type);
    this.channel?.invokeMethod("onShareResponse", resp);
  }
}
