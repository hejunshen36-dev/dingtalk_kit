import 'package:dingtalk_kit/response/dingtalk_response.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:dingtalk_kit/dingtalk_kit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _dingtalkVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();

    DingtalkKit.responseStream.listen(_handleResponse);
  }

  Future<void> initPlatformState() async {
    String dingtalkVersion;
    try {
      dingtalkVersion = await DingtalkKit.openAPIVersion();
      print("钉钉SDK: ===> versionSDK: $dingtalkVersion");
      // Replace the App ID and keep the iOS URL Scheme in sync before device testing.
      bool isSupport = await DingtalkKit.registerApp(
          "YOUR_DINGTALK_APP_ID", "com.example.dingtalkkitexample");
      print("注册成功: $isSupport");
    } on PlatformException {
      dingtalkVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _dingtalkVersion = dingtalkVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dingtalk SDK Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('dingtalkVersion: $_dingtalkVersion\n'),
              TextButton(
                onPressed: () {
                  DingtalkKit.isDingTalkInstalled().then((value) {
                    print("是否安装了钉钉: $value");
                  });
                },
                child: Text('isDingTalkInstalled'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.isDingTalkSupportSSO().then((value) {
                    print("是否支持登录: $value");
                  });
                },
                child: Text('isDingTalkSupportSSO'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.openDingTalk()
                      .then((value) => print("打开钉钉App: $value"));
                },
                child: Text('openDingTalk'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.sendAuth("Auth").then(
                    (value) => print("打开钉钉登录: $value"),
                  );
                },
                child: Text('sendAuthDingTalk'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.sendTextMessage('分享文本');
                },
                child: Text('shareText'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.sendImageMessage(
                      picUrl:
                          'https://www.baidu.com/img/PCtm_d9c8750bed0b3c7d089fa7d55720d6cf.png');
                },
                child: Text('shareImage'),
              ),
              TextButton(
                onPressed: () {
                  DingtalkKit.sendWebPageMessage(
                    'https://www.baidu.com/',
                    title: '标题',
                    content: '描述2333',
                    thumbUrl:
                        'https://www.baidu.com/img/PCtm_d9c8750bed0b3c7d089fa7d55720d6cf.png',
                  );
                },
                child: Text('shareWebPage'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 钉钉回调监听
  void _handleResponse(event) {
    if (event is DingtalkAuthResponse) {
      var response = event;
      if (response.code.isNotEmpty) {
        print("Authorization response received");
      } else {
        print(response.errorMessage);
      }
    }
  }
}
