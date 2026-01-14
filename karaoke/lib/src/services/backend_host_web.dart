import 'dart:html' as html;

String getBackendHost() => html.window.location.hostname ?? 'localhost';

