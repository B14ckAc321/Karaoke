import 'package:flutter/material.dart';
import 'package:karaoke/src/services/backend_service.dart';
import 'package:karaoke/src/services/theme_service.dart';

final class TvPage extends StatefulWidget {
  const TvPage({super.key});

  @override
  State<TvPage> createState() => _TvPageState();
}

class _TvPageState extends State<TvPage> {
  final backend = BackendService.getInstance();
  final themeService = ThemeService.getInstance();

  @override
  void initState() {
    super.initState();
    backend.addListener(_onUpdate);
    themeService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    backend.removeListener(_onUpdate);
    themeService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF0b0f1a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = backend.state;
    final timer = state?.timer;
    final minutes = timer != null ? (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0') : '--';
    final seconds = timer != null ? (timer.remainingSeconds % 60).toString().padLeft(2, '0') : '--';
    final bgColor = _parseColor(themeService.backgroundColor);
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    final primaryColor = _parseColor(themeService.primaryColor);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [
        if (themeService.backgroundImageUrl != null)
          Positioned.fill(
            child: Image.network(themeService.backgroundImageUrl!, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.3)),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (themeService.logoImageUrl != null)
              Image.network(themeService.logoImageUrl!, height: 120, fit: BoxFit.contain)
            else
              Text('Karaoke', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryColor, fontFamily: themeService.fontFamily, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20)]),
                child: state == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: state.songs.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withOpacity(0.3)),
                        itemBuilder: (context, i) {
                          final s = state.songs[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              title: Text(s.title, style: TextStyle(fontSize: themeService.titleFontSize, fontWeight: FontWeight.w600, color: textColor, fontFamily: themeService.fontFamily)),
                              subtitle: s.artist != null ? Text(s.artist!, style: TextStyle(fontSize: themeService.titleFontSize * 0.65, color: textColor.withOpacity(0.8), fontFamily: themeService.fontFamily)) : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(20)),
                                child: Text('${s.score}', style: TextStyle(fontSize: themeService.scoreFontSize, fontWeight: FontWeight.bold, color: bgColor, fontFamily: themeService.fontFamily)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 3),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Text('$minutes:$seconds', style: TextStyle(fontSize: themeService.timerFontSize, fontWeight: FontWeight.w900, color: accentColor, fontFamily: themeService.fontFamily, shadows: [Shadow(color: primaryColor, blurRadius: 15)])),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}



