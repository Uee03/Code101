import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'core/config.dart';
import 'core/url_policy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  String message;
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
    UrlPolicy.validate(Config.issuer, debug: kDebugMode);
    message = 'Setup ready: generated client, configuration and icons.';
  } on FormatException catch (error) {
    message = error.message;
  }
  runApp(MaterialApp(home: Scaffold(body: SafeArea(child: Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SvgPicture.asset('assets/icons/team.svg', width: 48, height: 48,
        semanticsLabel: 'Teams',
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
      Text(message, textAlign: TextAlign.center),
    ]),
  )))));
}
