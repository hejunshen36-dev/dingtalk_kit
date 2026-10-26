# 钉钉原生 SDK

2026-10-23 按[钉钉官方接入流程](https://open.dingtalk.com/document/dingstart/mini-app-access)核对。

| 平台 | 当前使用 | 来源 |
| --- | --- | --- |
| Android | `ddsharesdk-1.2.2.jar`，替代 Maven 1.2.0 | [官方下载 ZIP](https://help-static-aliyun-doc.aliyuncs.com/file-manage-files/zh-CN/20260325/qrxlhj/Android%E5%88%86%E4%BA%AB%E5%B7%A5%E5%85%B7%E5%8C%85.zip) |
| iOS | DTShareKit 3.1.0 XCFramework，替代 3.0.0 Framework | [官方下载 ZIP](https://files.alicdn.com/tpsservice/94a5e78286e0d71c935165a28da1514b.zip) |
| OHOS | `@dingtalk/ddsharesdk` 1.1.5 | [官方 HAR](https://help-static-aliyun-doc.aliyuncs.com/file-manage-files/zh-CN/20251031/zqfluo/ddsharesdk.har) |

官方页面的 Android 表格仍写 1.2.0.3，但其链接中的 JAR 文件名是 1.2.2；以实际官方下载产物固定依赖，不猜测 Maven 是否发布该版本。官方表格 MD5 与下载产物不一致，以下记录实际 SHA-256。OHOS 原有 HAR 与本次官方文件逐字节相同，因此保留原文件。

| 文件 | SHA-256 |
| --- | --- |
| `android/libs/ddsharesdk-1.2.2.jar` | `6067092a709aaa0536719c1989c690fd104220b85a3f38b037509a0c9384e160` |
| `ios/Libraries/DTShareKit.xcframework/ios-arm64/DTShareKit.framework/DTShareKit` | `a3c144bc26e3f8545bb3900fb70e1426526f15d3cbe8646a96ab31d46b6fc39f` |
| `ios/Libraries/DTShareKit.xcframework/ios-arm64_x86_64-simulator/DTShareKit.framework/DTShareKit` | `f37656cef8fc10f1ae227059ea7070d47f9a0e9fdb3148704f3257a9cbb59e80` |
| `ohos/src/libs/ddsharesdk.har` | `7197407470c4d18aa497c02ab27a756e33e23cbc0a3d99f1648c9e0048357712` |

## 接入与结果语义

- Android 的文本、网页、图片请求将 `sendReq` / `sendReqToDing` 的 boolean 回传 Flutter。校验失败或原生异常只完成一次调用，且不继续发送。插件声明标准钉钉包可见性，回调 alias 继续使用宿主 applicationId。
- Android 回调通过 `onCreate` / `onNewIntent` 共用入口处理，新 Intent 先写回 Activity。注册时仅保存公开 App ID，进程重建后用它创建回调局部 SDK 实例，不把回调 Activity 留在全局单例。升级后需正常启动并注册一次；无注册记录、无法识别的 Intent 或异常均退出。回调仍经现有 MethodChannel 通知；Flutter 引擎/监听器尚未启动时，不承诺恢复进程退出前的 Dart 请求或重放结果，不持久化授权码。
- 收到有效响应后，通过宿主自身的 launcher Intent 和 `NEW_TASK | SINGLE_TOP` 恢复宿主任务，再结束回调 Activity；适配宿主 MainActivity 为 `singleInstance`、与回调分属不同任务的情况。不使用 `CLEAR_TASK` / `CLEAR_TOP`，不转发回调 extras；无效 Intent 不唤起宿主。该行为依赖钉钉实际发出响应回调。
- iOS 最低 12.0；XCFramework 含 arm64 真机及 arm64/x86_64 模拟器。3.1.0 的旧同步发送/打开方法固定返回 YES，必须使用 completion。更新后在宿主 iOS 目录运行 `pod install --no-repo-update`。
- OHOS 最低 API12；宿主需启用 `useNormalizedOHMUrl=true`。图片使用本地路径转换后的 `file://` URI，远程图片由调用方先下载，不能把 HTTP URL 直接交给 SDK。分享及打开操作均回传同步/异步错误。
- 返回 true 仅表示 SDK 接受派发，不表示用户已发送。后台必须配置与安装包一致的 Android 包名/签名、iOS Bundle ID、OHOS Bundle Name/appIdentifier（非 appId）。

## 回归

从插件目录运行 `flutter test --no-pub test`，覆盖 Dart 方法路由、响应流、分享/授权响应类型及错误码数值；iOS 字段契约通过源码检查覆盖，不能替代原生运行验证。

在集成此插件的 Android 应用工程中运行 Gradle 任务 `:dingtalk_kit:testDebugUnitTest :dingtalk_kit:assembleDebug`，覆盖真实 Kotlin handler 的接受/拒绝、Ding 分支、未注册、异常及无效图片早退。
Robolectric 生命周期回归覆盖单例丢失后的分享/授权响应、新 Intent 替换、无效 Intent 与缺少注册记录时退出；首次执行需下载 Android 测试运行库。
参数对照用例按官方 Demo 构造文本、网页和在线图片请求，逐字段比较序列化 Bundle，并覆盖普通分享与 Ding 两个发送分支。Demo 的 transaction 未设置、媒体对象 SDK 字段默认为 0，均不单独视为缺陷。
调用方还应验证派发语义、连续分享、迟到回调与失败重试。
原生编译和替身测试不能证明实际钉钉后台配置或用户分享结果；真实设备仍需检查文本/网页/图片调起、取消、回跳和连续两次分享。
