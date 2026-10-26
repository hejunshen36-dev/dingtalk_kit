import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dingtalk_kit/dingtalk_kit.dart';

void main() {
  const MethodChannel channel = MethodChannel('dingtalk_kit');

  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return call.method == 'openAPIVersion' ? '42' : true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('openAPIVersion forwards the native version result', () async {
    expect(await DingtalkKit.openAPIVersion(), '42');
    expect(calls.single.method, 'openAPIVersion');
    expect(calls.single.arguments, isNull);
  });

  test('isDingTalkInstalled uses the SDK-aligned channel method', () async {
    expect(await DingtalkKit.isDingTalkInstalled(), isTrue);
    expect(calls.single.method, 'isDingTalkInstalled');
    expect(calls.single.arguments, isNull);
  });

  test('isDingTalkSupportSSO invokes the SSO capability query', () async {
    expect(await DingtalkKit.isDingTalkSupportSSO(), isTrue);
    expect(calls.single.method, 'isDingTalkSupportSSO');
    expect(calls.single.arguments, isNull);
  });

  test('openDingTalk invokes the native open operation', () async {
    expect(await DingtalkKit.openDingTalk(), isTrue);
    expect(calls.single.method, 'openDingTalk');
    expect(calls.single.arguments, isNull);
  });
}
