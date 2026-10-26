# 发布到 pub.dev

需要 Flutter SDK、Python 3，以及对 pub.dev 包 `dingtalk_kit` 的发布权限。首次发布时按 Pub 提示在浏览器登录。账号和令牌由 Pub 管理，不写入仓库。

在插件目录执行：

```sh
./tool/publish.sh --dry-run  # 完整预检，不上传
./tool/publish.sh            # 预检通过后直接发布
```

可从任意目录调用脚本；指定 SDK 使用 `FLUTTER_BIN=/path/to/flutter ./tool/publish.sh`。

每次发布前手动更新 `pubspec.yaml` 的版本和 `CHANGELOG.md`；已发布版本不能覆盖。`repository` 已设置为公开源码仓库 https://github.com/hejunshen36-dev/dingtalk_kit，请保持地址有效，不要填写内部仓库地址。发布脚本保留对缺少 `homepage` / `repository` 建议配置警告的兼容处理；其他警告、错误或检查失败仍阻止上传，不使用全局忽略警告或跳过验证选项；无法识别的诊断也会停止上传。

脚本在临时目录生成发布快照，执行依赖解析、静态检查、插件测试和 `pub publish --dry-run`，通过后才执行 `pub publish --force`。预检日志放在发布目录之外，不打入包。退出时删除临时目录，不变更工作区依赖或版本。pubspec 不设置 `publish_to`，使用 Pub 默认的 pub.dev 目标。

发布清单包含 Dart、三端源码、必要的 JAR/XCFramework/HAR、测试、公共文档和精简 Dart 示例。示例平台工程、构建缓存、宿主产物、签名及本地配置不包含在包中。精简示例只包含代码和使用说明；设备验证请使用自己的应用。维护者发布说明和示例本地依赖配置不包含在包中。

Android/iOS 可使用官方 Flutter，OHOS 构建需要兼容的 Flutter OHOS 工具链。预检通过不代表完成真实钉钉分享回跳验证。首次发布还需由 pub.dev 服务端确认包名可用及账号权限。
