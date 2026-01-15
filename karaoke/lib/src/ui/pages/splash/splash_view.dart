import 'package:flutter/material.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/services/app_service.dart';
import 'package:karaoke/src/services/backend_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final backend = BackendService.getInstance();
  final appService = AppService.getInstance();

  @override
  void initState() {
    super.initState();
    backend.addListener(_onUpdate);
    appService.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => onStartUp());
  }

  @override
  void dispose() {
    backend.removeListener(_onUpdate);
    appService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Future<void> onStartUp() async {
    await appService.onAppStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.appTitle,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            // Connection status
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        backend.isConnected ? Icons.check_circle : Icons.error,
                        color: backend.isConnected ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Backend Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: backend.isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    backend.connectionStatus,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  Builder(
                    builder: (context) {
                      try {
                        final url = backend.baseUrl;
                        if (url.isNotEmpty) {
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'URL: $url',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Using relative URLs (same origin)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          );
                        }
                      } catch (e) {
                        return Column(
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'URL not initialized yet',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // App initialization status
            Text(
              appService.initialized ? 'App initialized' : 'Initializing app...',
              style: TextStyle(
                fontSize: 14,
                color: appService.initialized ? Colors.green : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
