import 'dart:async';
import 'dart:io';

import 'package:dingtalk_kit/dingtalk_kit.dart';
import 'package:dingtalk_kit/response/dingtalk_response.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dingtalk_kit');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    // Initialize the real Dart callback handler before delivering native events.
    await DingtalkKit.registerApp('test-app-id', 'test.bundle');
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> receive(String method, Map<String, Object?> payload) async {
    final reply = Completer<ByteData?>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, payload)),
      reply.complete,
    );
    // Decoding the reply surfaces callback exceptions instead of letting a
    // broken response parser silently pass or wait for the stream indefinitely.
    expect(codec.decodeEnvelope((await reply.future)!), isTrue);
  }

  test('iOS share dictionary matches the Dart callback contract', () {
    // Support test commands run from the plugin or its parent integration package.
    const path = 'ios/Classes/DingtalkKitPlugin.m';
    final source = [File(path), File('plugins/dingtalk_kit/$path')]
        .firstWhere((file) => file.existsSync())
        .readAsStringSync();
    // Guard the producer too: channel tests alone cannot detect a native key
    // being renamed or an NSNumber being replaced with an NSString.
    final dictionary = RegExp(
      r'DTSendMessageToDingTalkResp\s*\*\s*\w+.*?'
      r'NSDictionary\s*\*\s*result\s*=\s*@\{(.*?)\};',
      dotAll: true,
    ).firstMatch(source);
    expect(dictionary, isNotNull);
    final fields = <String, String>{
      for (final match in RegExp(r'@"(\w+)"\s*:\s*([^,\n]+)')
          .allMatches(dictionary!.group(1)!))
        match.group(1)!: match.group(2)!.trim(),
    };
    expect(fields.keys,
        unorderedEquals(['errCode', 'errStr', 'mTransaction', 'type']));
    expect(fields['errCode'], matches(r'^@\(\w+\.errorCode\)$'));
    expect(fields['errStr'], matches(r'^\w+\.errorMessage\s*\?:\s*@""$'));
    expect(fields['mTransaction'], '@""');
    expect(fields['type'], '@2');
  });

  test('renamed error code constants retain the SDK values', () {
    expect({
      'success': DingtalkErrorCode.ERR_OK,
      'common': DingtalkErrorCode.ERR_COMM,
      'cancel': DingtalkErrorCode.ERR_USER_CANCEL,
      'sendFailed': DingtalkErrorCode.ERR_SENT_FAILED,
      'authDenied': DingtalkErrorCode.ERR_AUTH_DENIED,
      'unsupported': DingtalkErrorCode.ERR_UNSUPPORT,
    }, {
      'success': 0,
      'common': -1,
      'cancel': -2,
      'sendFailed': -3,
      'authDenied': -4,
      'unsupported': -5,
    });
  });

  for (final code in [0, -1, -2, -3, -4, -5]) {
    test('share callback preserves error code $code and reaches the stream',
        () async {
      final responses = <DingtalkResponse>[];
      final subscription =
          DingtalkKit.responseStream.listen(responses.add);
      addTearDown(subscription.cancel);
      final message = code == 0 ? '' : 'SDK error $code';

      await receive('onShareResponse', {
        'errCode': code,
        'errStr': message,
        'mTransaction': '',
        'type': 2,
      });
      await pumpEventQueue();

      expect(responses, hasLength(1));
      final response = responses.single as DingtalkShareResponse;
      expect(response.errorCode, code);
      expect(response.errorMessage, message);
      expect(response.transaction, '');
      expect(response.type, 2);
      expect(response.isSuccessful, code == 0);
    });
  }

  test('authorization callbacks keep their separate response type', () async {
    final responses = <DingtalkResponse>[];
    final subscription =
        DingtalkKit.responseStream.listen(responses.add);
    addTearDown(subscription.cancel);

    await receive('onAuthResponse', {
      'errCode': 0,
      'errStr': '',
      'mTransaction': 'test-transaction',
      'code': 'test-authorization-code',
      'state': 'test-state',
    });
    await pumpEventQueue();

    expect(responses, hasLength(1));
    final response = responses.single as DingtalkAuthResponse;
    expect(response.code, 'test-authorization-code');
    expect(response.state, 'test-state');
    expect(response.errorCode, 0);
    expect(response.errorMessage, '');
    expect(response.transaction, 'test-transaction');
    expect(response.isSuccessful, isTrue);
  });
}
