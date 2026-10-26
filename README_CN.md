# dingtalk_kit

支持 Android、iOS 和 OHOS 的钉钉 Flutter 插件，提供文本、网页、图片分享及授权能力。[English](README.md)

## 安装

```sh
flutter pub add dingtalk_kit
```

该命令会选择与当前 SDK 兼容的最新稳定版本，并将依赖约束写入应用的 `pubspec.yaml`。

也可以直接在应用的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  dingtalk_kit: any
```

`any` 不限定依赖版本，但解析结果仍受 SDK、其他依赖及锁文件影响，不保证每次解析都会升级到最新版。

## 平台支持

| 能力 | Android | iOS | OHOS |
| --- | --- | --- | --- |
| 注册、检查安装、打开钉钉 | 支持 | 支持 | 支持 |
| 文本、网页、图片分享 | 支持 | 支持 | 支持 |
| SSO 查询、授权请求 | 支持 | 支持 | 返回 `false` |

暂不支持音乐和视频分享。OHOS 应用需使用兼容的 Flutter OHOS 工具链。

## 平台配置

先在钉钉开放平台创建应用，完成平台身份配置，再进行设备测试。

- **Android：**登记应用包名与签名信息。插件已声明钉钉包可见性查询，并通过应用的 applicationId 配置回调 Activity alias。
- **iOS：**插件要求 iOS 12.0 或更高版本，同时需满足所用 Flutter SDK 的最低系统版本。配置与钉钉 App ID 一致的 URL Scheme，在 `Info.plist` 的 `LSApplicationQueriesSchemes` 中加入 `dingtalk`、`dingtalk-open`、`dingtalk-sso`。注册时传入应用真实的 Bundle ID。
- **OHOS：**要求 API 12 或更高版本，并在应用构建配置中启用 `useNormalizedOHMUrl=true`。在钉钉开放平台登记 Bundle Name 和 appIdentifier；appIdentifier 与钉钉 App ID 不同。

添加或更新插件后，重新构建应用以载入原生实现。

## 使用

先注册，再调用其他原生能力：

```dart
import 'package:dingtalk_kit/dingtalk_kit.dart';

final registered = await DingtalkKit.registerApp(
  'YOUR_DINGTALK_APP_ID',
  'YOUR_IOS_BUNDLE_ID',
);

if (registered && await DingtalkKit.isDingTalkInstalled()) {
  await DingtalkKit.sendTextMessage('来自 Flutter 的分享');
}
```

### 网页分享

```dart
final accepted = await DingtalkKit.sendWebPageMessage(
  'https://example.com',
  title: '示例网页',
  content: '分享内容简介',
  thumbUrl: 'https://example.com/thumbnail.png',
);
```

### 图片分享

```dart
final accepted = await DingtalkKit.sendImageMessage(
  picUrl: imageUrl,
  picPath: localImagePath,
);
```

至少提供一个图片来源。iOS 使用 `picUrl`；Android 在两项同时提供时优先使用 `picUrl`。OHOS 要求 `picPath` 为本地路径或 `file://` URI，远程图片需由应用自行下载后再分享。示例中的 `imageUrl` 和 `localImagePath` 由应用提供。

### 响应与授权

```dart
import 'package:dingtalk_kit/response/dingtalk_response.dart';

final subscription = DingtalkKit.responseStream.listen((response) {
  if (response is DingtalkShareResponse) {
    // 处理 response.isSuccessful、response.errorCode、response.errorMessage。
  } else if (response is DingtalkAuthResponse) {
    // 处理 response.code、response.state；不要记录授权码日志。
  }
});

if (await DingtalkKit.isDingTalkSupportSSO()) {
  await DingtalkKit.sendAuth('YOUR_STATE');
}
```

在发送请求前订阅响应，不再使用时取消 `subscription`。`responseStream` 是广播流 `Stream<DingtalkResponse>`。公共属性为 `errorCode`、`errorMessage`、`transaction` 和 `isSuccessful`；分享响应另有 `type`，授权响应另有 `code`、`state`。错误码通过 `DingtalkErrorCode.ERR_*` 访问，数值为 0 至 -5。

分享方法返回 `true` 仅表示 SDK 接受派发，不代表用户已完成分享。返回应用不一定产生结果回调。授权结果异步返回，OHOS 暂不支持授权；`state` 的处理依赖平台实现，不应假设各平台都会原样回传。

## 其他操作

- `DingtalkKit.openDingTalk()`：打开钉钉。
- `DingtalkKit.openAPIVersion()`：Android 返回授权协议版本，iOS 返回原生 API 版本字符串，OHOS 返回空字符串；不宜跨平台直接比较。

请使用已安装钉钉且平台身份配置正确的设备，验证实际分享、取消与回跳行为。
