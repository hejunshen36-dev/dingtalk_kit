// 通道字段保持与三端原生实现一致，独立于 Dart 属性命名。
const String _errorCodeKey = "errCode";
const String _errorMessageKey = "errStr";
const String _transactionKey = "mTransaction";

typedef _ResponseFactory = DingtalkResponse Function(Map argument);

/// 原生回调方法名与响应类型的映射。
Map<String, _ResponseFactory> _responseFactories = {
  "onShareResponse": (Map argument) => DingtalkShareResponse.fromMap(argument),
  "onAuthResponse": (Map argument) => DingtalkAuthResponse.fromMap(argument),
};

/// 钉钉原生响应的公共字段。
class DingtalkResponse {
  final int errorCode;
  final String errorMessage;
  final String transaction;

  bool get isSuccessful => errorCode == 0;

  DingtalkResponse._(this.errorCode, this.errorMessage, this.transaction);

  /// 根据原生回调方法名解析对应响应。
  factory DingtalkResponse.create(String name, Map argument) =>
      _responseFactories[name]!(argument);
}

/// 钉钉分享响应。
class DingtalkShareResponse extends DingtalkResponse {
  final int type;

  DingtalkShareResponse.fromMap(Map map)
      : type = map["type"],
        super._(map[_errorCodeKey], map[_errorMessageKey] ?? "",
            map[_transactionKey] ?? "");
}

/// 钉钉授权响应；code 为授权码，state 为回传状态。
class DingtalkAuthResponse extends DingtalkResponse {
  final String code;
  final String state;

  DingtalkAuthResponse.fromMap(Map map)
      : code = map["code"],
        state = map["state"] ?? "",
        super._(map[_errorCodeKey], map[_errorMessageKey] ?? "",
            map[_transactionKey] ?? "");
}

/// 钉钉 SDK 响应错误码。
class DingtalkErrorCode {
  static const ERR_OK = 0;
  static const ERR_COMM = -1;
  static const ERR_USER_CANCEL = -2;
  static const ERR_SENT_FAILED = -3;
  static const ERR_AUTH_DENIED = -4;
  static const ERR_UNSUPPORT = -5;
}
