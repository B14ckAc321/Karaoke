import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/navigation/app_router.dart';
import 'package:karaoke/src/ui/theme/karaoke_theme.dart';

/// The Widget that configures your application.
class Karaoke extends StatelessWidget {
  const Karaoke({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.getInstance().router,
      restorationScopeId: 'karaoke',

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
      ],

      onGenerateTitle: (BuildContext context) =>
        AppLocalizations.of(context)!.appTitle,

      theme: KaraokeTheme.light(),
      darkTheme: KaraokeTheme.dark(),

    );
  }
}
