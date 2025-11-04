import 'package:flutter/material.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/services/app_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => onStartUp());
    super.initState();
  }

  Future<void> onStartUp() async {
    await AppService.getInstance().onAppStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Text(AppLocalizations.of(context)!.appTitle),
      ),
    );
  }
}
