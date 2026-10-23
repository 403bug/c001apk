import 'dart:io';

import 'package:c001apk_flutter/utils/storage_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preview startup never opens the stable legacy account directory',
      () async {
    final root = await Directory.systemTemp.createTemp('c001apk-preview-');
    final current = Directory('${root.path}/c001apk M3E');
    final legacy = Directory('${root.path}/c001apk-flutter/hive');
    await current.create();
    Hive.init(legacy.path);
    final box = await Hive.openBox('settings');
    await box.putAll({
      SettingsBoxKey.installTime: '1700000000000',
      SettingsBoxKey.token: 'synthetic-stable-account',
    });
    await Hive.close();
    final legacyFile = File('${legacy.path}/settings.hive');
    final before = await legacyFile.readAsBytes();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => current.path);
    try {
      await GStorage.init();
      expect(GStorage.token, isNot('synthetic-stable-account'));
      expect(GStorage.installTime, isNot('1700000000000'));
      expect(await legacyFile.readAsBytes(), before);
      expect(await File('${current.path}/hive/settings.hive').exists(), isTrue);
    } finally {
      await Hive.close();
      await root.delete(recursive: true);
    }
  });
}
