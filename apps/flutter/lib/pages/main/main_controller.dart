// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import "package:flutter/foundation.dart";

import '../../logic/network/network_repo.dart';
import '../../logic/network/api_failure.dart';
import '../../logic/model/check_info/check.dart';
import '../../utils/extensions.dart';
import '../../utils/global_data.dart';
import '../../utils/storage_util.dart';

class MainController extends GetxController {
  Future<void> checkLoginInfo() async {
    try {
      Response response = await NetworkRepo.checkLoginInfo();
      if (response.statusCode == HttpStatus.ok) {
        // A challenge or incomplete response must not erase a working session.
        if (response.data is Map && response.data['message'] == '登录信息有误') {
          GStorage.setUid('');
          GStorage.setUsername('');
          GStorage.setToken('');
          GStorage.setIsLogin(false);
          return;
        }
        readApiObject(response);
        CheckInfo responseData = CheckInfo.fromJson(response.data);
        if (responseData.data != null) {
          final data = responseData.data!;
          if (!data.uid.isNullOrEmpty && !data.token.isNullOrEmpty) {
            GStorage.setUid(data.uid!);
            GStorage.setUsername(Uri.encodeComponent(data.username.orEmpty));
            GStorage.setToken(data.token!);
            GStorage.setIsLogin(true);
          }
        }
      } else {
        debugPrint('statusCode: ${response.statusCode}');
      }
      for (final cookie in response.headers['Set-Cookie'] ?? <String>[]) {
        final pair = cookie.split(';').first;
        if (pair.startsWith('SESSID=')) GlobalData().SESSID = pair;
      }
    } catch (e) {
      debugPrint('登录检查：${ApiFailure.fromError(e).message}');
    }
  }
}
