import 'package:flutter/material.dart';

final class ScaffoldWithNavBarDestination extends NavigationDestination {
  const ScaffoldWithNavBarDestination({required this.initialLocation, required super.icon, required super.label, super.key});
  final String initialLocation;
}
