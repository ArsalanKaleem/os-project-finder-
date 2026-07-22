import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import '/core/storage/local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive works on every Flutter target (web included), which is why it backs
  // all local persistence: bookmarks, history, settings and offline cache.
  await LocalStorage.init();

  runApp(const ProviderScope(child: ForgeOSApp()));
}
