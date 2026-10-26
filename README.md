# dingtalk_kit

A Flutter plugin for DingTalk sharing and authorization on Android, iOS and OHOS. [中文说明](README_CN.md)

## Installation

```sh
flutter pub add dingtalk_kit
```

This command selects the latest stable version compatible with your SDK and writes the dependency constraint to `pubspec.yaml`.

Alternatively, add the dependency directly to your application's `pubspec.yaml`:

```yaml
dependencies:
  dingtalk_kit: any
```

`any` leaves the version unrestricted, but resolution still depends on your SDK, other dependencies and the lockfile. It does not automatically upgrade to the latest version on every resolution.

## Platform support

| Capability | Android | iOS | OHOS |
| --- | --- | --- | --- |
| Registration, installation check, opening DingTalk | Supported | Supported | Supported |
| Text, webpage and image sharing | Supported | Supported | Supported |
| SSO check and authorization | Supported | Supported | Returns `false` |

Music and video sharing are not supported. OHOS requires a compatible Flutter OHOS toolchain.

## Platform configuration

Create an application in the DingTalk developer console and configure its platform identifiers before testing on a device.

- **Android:** register your application's package name and signing information. The plugin declares the DingTalk package query and callback Activity alias using your applicationId.
- **iOS:** requires iOS 12.0 or later, as well as the minimum version required by your Flutter SDK. Configure a URL Scheme matching your DingTalk App ID. Add `dingtalk`, `dingtalk-open` and `dingtalk-sso` to `LSApplicationQueriesSchemes` in `Info.plist`. Pass your application's actual Bundle ID when registering.
- **OHOS:** requires API 12 or later and `useNormalizedOHMUrl=true` in the application build configuration. Register your Bundle Name and appIdentifier in the DingTalk console; appIdentifier is distinct from the DingTalk App ID.

After adding or updating the plugin, rebuild your application to include its native implementation.

## Usage

Register before invoking other native operations:

```dart
import 'package:dingtalk_kit/dingtalk_kit.dart';

final registered = await DingtalkKit.registerApp(
  'YOUR_DINGTALK_APP_ID',
  'YOUR_IOS_BUNDLE_ID',
);

if (registered && await DingtalkKit.isDingTalkInstalled()) {
  await DingtalkKit.sendTextMessage('Hello from Flutter');
}
```

### Webpage sharing

```dart
final accepted = await DingtalkKit.sendWebPageMessage(
  'https://example.com',
  title: 'Example',
  content: 'A webpage shared with DingTalk',
  thumbUrl: 'https://example.com/thumbnail.png',
);
```

### Image sharing

```dart
final accepted = await DingtalkKit.sendImageMessage(
  picUrl: imageUrl,
  picPath: localImagePath,
);
```

Supply at least one image source. iOS uses `picUrl`; Android prefers `picUrl` when both arguments are provided. OHOS requires `picPath` to be a local path or `file://` URI; download remote images yourself before sharing. `imageUrl` and `localImagePath` above are values supplied by your application.

### Responses and authorization

```dart
import 'package:dingtalk_kit/response/dingtalk_response.dart';

final subscription = DingtalkKit.responseStream.listen((response) {
  if (response is DingtalkShareResponse) {
    // Handle response.isSuccessful, response.errorCode and response.errorMessage.
  } else if (response is DingtalkAuthResponse) {
    // Handle response.code and response.state; do not log authorization codes.
  }
});

if (await DingtalkKit.isDingTalkSupportSSO()) {
  await DingtalkKit.sendAuth('YOUR_STATE');
}
```

Subscribe before sending requests and cancel `subscription` when no longer needed. `responseStream` is a broadcast `Stream<DingtalkResponse>`. Common properties are `errorCode`, `errorMessage`, `transaction` and `isSuccessful`. Share responses add `type`; authorization responses add `code` and `state`. Error constants are available as `DingtalkErrorCode.ERR_*` (values 0 through -5).

A share method returning `true` means the SDK accepted dispatch, not that the user completed sharing. Do not assume every return to your application produces a result callback. Authorization results arrive asynchronously; OHOS does not support authorization. State handling depends on the platform SDK implementation; do not assume it is echoed on every platform.

## Other operations

- `DingtalkKit.openDingTalk()` opens DingTalk.
- `DingtalkKit.openAPIVersion()` returns the authorization protocol version on Android, a native API version string on iOS, and an empty string on OHOS. These values are not directly comparable across platforms.

Test actual sharing, cancellation and return-to-app behavior on devices with DingTalk installed and correctly configured application identifiers.
