import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Host test runs have no platform plugins, so the sqflite factory has to be
/// backed by the FFI implementation instead of the mobile plugin. The cache
/// manager used by CachedNetworkImage opens a database during setup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}