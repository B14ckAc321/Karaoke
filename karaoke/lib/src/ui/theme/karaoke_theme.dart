import 'package:flutter/material.dart';
import 'package:karaoke/src/ui/theme/karaoke_colors.dart';

class KaraokeTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const <ThemeExtension<dynamic>>[
        KaraokeColors(
          primaryColor: Colors.blue,
          lightPrimaryColor: Colors.blueAccent,
          secondaryColor: Colors.green,
          lightSecondaryColor: Colors.greenAccent,
        )
      ],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const <ThemeExtension<dynamic>>[
        KaraokeColors(
          primaryColor: Colors.deepOrange,
          lightPrimaryColor: Colors.deepOrangeAccent,
          secondaryColor: Colors.deepPurple,
          lightSecondaryColor: Colors.deepPurpleAccent,
        )
      ],
    );
  }
}