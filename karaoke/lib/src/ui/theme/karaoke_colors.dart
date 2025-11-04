import 'package:flutter/material.dart';

final class KaraokeColors extends ThemeExtension<KaraokeColors> {
  final Color primaryColor;
  final Color lightPrimaryColor;
  final Color secondaryColor;
  final Color lightSecondaryColor;

  const KaraokeColors({
    required this.primaryColor,
    required this.lightPrimaryColor,
    required this.secondaryColor,
    required this.lightSecondaryColor,
  });

  @override
  ThemeExtension<KaraokeColors> copyWith({
    Color? primaryColor,
    Color? lightPrimaryColor,
    Color? secondaryColor,
    Color? lightSecondaryColor,
  }) {
    return KaraokeColors(
      primaryColor: primaryColor ?? this.primaryColor,
      lightPrimaryColor: lightPrimaryColor ?? this.lightPrimaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      lightSecondaryColor: lightSecondaryColor ?? this.lightSecondaryColor,
    );
  }

  @override
  KaraokeColors lerp(ThemeExtension<KaraokeColors>? other, double t) {
    if (other is! KaraokeColors) {
      return this;
    }

    return KaraokeColors(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      lightPrimaryColor: Color.lerp(lightPrimaryColor, other.lightPrimaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      lightSecondaryColor: Color.lerp(lightSecondaryColor, other.lightSecondaryColor, t)!,
    );
  }
}
