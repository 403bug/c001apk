import 'dart:async';
import 'package:dio/dio.dart';

import '../../logic/network/interceptor.dart';
import '../../utils/global_data.dart';
import 'captcha_challenge.dart';

class Request {
  static final Request _instance = Request._internal();
  static late final Dio dio;
  factory Request() => _instance;
  Future<String?> Function(CaptchaChallenge)? captchaVerifier;
  bool _verifying = false;

  Request._internal() {
    dio = Dio()
      ..options.connectTimeout = const Duration(milliseconds: 5000)
      ..options.receiveTimeout = const Duration(milliseconds: 5000)
      ..interceptors.add(ApiInterceptor());
  }

  Future<Response<dynamic>> get(
    url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    extra,
  }) async {
    final session =
        (GlobalData().isLogin, GlobalData().uid, GlobalData().token);
    final response = await dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _verifyAndRetry(
        response,
        session,
        options?.extra?['skipCaptcha'] == true,
        (proof, challenge) => dio.get(url,
            queryParameters: {...?queryParameters, challenge.field: proof},
            options: options,
            cancelToken: cancelToken));
  }

  Future<Response<dynamic>> post(
    url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    extra,
  }) async {
    final session =
        (GlobalData().isLogin, GlobalData().uid, GlobalData().token);
    // A multipart body becomes finalized during its first send; retain a copy
    // before sending so a server-rejected write can be retried exactly once.
    final retryData = data is FormData ? data.clone() : data;
    final response = await dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return _verifyAndRetry(
        response, session, options?.extra?['skipCaptcha'] == true,
        (proof, challenge) {
      Object? verifiedData = retryData;
      if (retryData is FormData) {
        retryData.fields.removeWhere((e) => e.key == challenge.field);
        retryData.fields.add(MapEntry(challenge.field, proof));
      } else if (retryData is Map<String, dynamic>) {
        verifiedData = {...retryData, challenge.field: proof};
      }
      return dio.post(url,
          data: verifiedData,
          queryParameters: verifiedData is FormData || verifiedData is Map
              ? queryParameters
              : {...?queryParameters, challenge.field: proof},
          options: options,
          cancelToken: cancelToken);
    });
  }

  Future<Response<dynamic>> _verifyAndRetry(
      Response<dynamic> response,
      (bool, String, String) session,
      bool skip,
      Future<Response<dynamic>> Function(String, CaptchaChallenge)
          retry) async {
    final uri = response.requestOptions.uri;
    if (skip ||
        _verifying ||
        captchaVerifier == null ||
        session !=
            (GlobalData().isLogin, GlobalData().uid, GlobalData().token) ||
        uri.scheme != 'https' ||
        !['api.coolapk.com', 'api2.coolapk.com'].contains(uri.host)) {
      return response;
    }
    final challenge = CaptchaChallenge.fromBody(response.data);
    if (challenge == null) return response;
    String? proof;
    _verifying = true;
    try {
      proof = await captchaVerifier!(challenge);
    } finally {
      _verifying = false;
    }
    if (proof == null ||
        !challenge.acceptsProof(proof) ||
        response.requestOptions.cancelToken?.isCancelled == true ||
        session !=
            (GlobalData().isLogin, GlobalData().uid, GlobalData().token)) {
      response.extra['captchaVerification'] =
          proof == null ? 'cancelled' : 'incomplete';
      return response;
    }
    // Direct Dio call, deliberately outside this helper: no verification loop,
    // network retries or replay after ambiguous transport errors.
    final verified = await retry(proof, challenge);
    verified.extra['captchaVerification'] = 'submitted';
    return verified;
  }
}
