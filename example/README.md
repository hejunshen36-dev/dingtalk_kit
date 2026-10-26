# dingtalk_kit 示例

`lib/main.dart` 演示插件注册、安装检查、授权和文本、网页、图片分享，使用 `DingtalkKit.responseStream` 订阅结果，并通过 `DingtalkAuthResponse` 读取授权响应。

## 在应用中使用

1. 创建或打开自己的 Flutter 应用，运行 `flutter pub add dingtalk_kit` 添加依赖。
2. 将示例代码复制到应用中，把 `YOUR_DINGTALK_APP_ID` 和示例 Bundle ID 替换为自己的配置。
3. 按插件 README 完成平台身份、iOS URL Scheme 和查询白名单配置。
4. 重新构建并在安装了钉钉的设备上验证。

发布包提供示例代码和使用说明，不包含独立运行所需的平台工程及依赖配置。OHOS 应用需使用兼容的 Flutter OHOS 工具链；远程图片需自行下载为本地文件后分享。

分享方法返回 `true` 仅表示 SDK 接受派发。授权回调、分享取消和回跳需通过设备验证，不要将真实授权码写入日志；页面退出时应取消响应订阅。
