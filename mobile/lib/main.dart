import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'controllers/auth_controller.dart';
import 'services/auth_api.dart';
import 'services/token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = AuthApi();
  final tokenStore = await TokenStore.create();
  final controller = AuthController(api: api, tokenStore: tokenStore);

  runApp(HotTakeApp(controller: controller));
  unawaited(controller.restoreSession());
}
