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
  bool _showWinningDialog = false;
  SongModel? _winningSong;

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

  void _onUpdate() {
    final state = backend.state;
    final timer = state?.timer;
    
    // Check if timer just ended (remainingSeconds == 0)
    if (timer != null && timer.remainingSeconds == 0 && state != null && state.songs.isNotEmpty) {
      // Find winning song
      final winningSong = state.songs.reduce((a, b) => a.score > b.score ? a : b);
      if (!_showWinningDialog || _winningSong?.id != winningSong.id) {
        setState(() {
          _showWinningDialog = true;
          _winningSong = winningSong;
        });
      }
    } else if (timer != null && timer.remainingSeconds == timer.durationSeconds && timer.remainingSeconds > 0) {
      // Timer was reset - hide dialog
      if (_showWinningDialog) {
        setState(() {
          _showWinningDialog = false;
          _winningSong = null;
        });
      }
    }
    setState(() {});
  }

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
    final secondaryColor = _parseColor(themeService.secondaryColor);
    
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
            Builder(
              builder: (context) {
                final customText1 = themeService.getThemeSetting('customText1') ?? '';
                final customText2 = themeService.getThemeSetting('customText2') ?? '';
                final customText3 = themeService.getThemeSetting('customText3') ?? '';
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (themeService.logoImageUrl != null)
                      Image.network(themeService.logoImageUrl!, height: 120, fit: BoxFit.contain)
                    else
                      Text('Karaoke', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryColor, fontFamily: themeService.fontFamily, shadows: [Shadow(color: accentColor, blurRadius: 10)])),
                    if (customText1.isNotEmpty || customText2.isNotEmpty || customText3.isNotEmpty) ...[
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (customText1.isNotEmpty)
                            Text(
                              customText1,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                fontFamily: themeService.fontFamily,
                                shadows: [
                                  Shadow(color: primaryColor, blurRadius: 12),
                                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8),
                                ],
                              ),
                            ),
                          if (customText2.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              customText2,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: themeService.fontFamily,
                                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                              ),
                            ),
                          ],
                          if (customText3.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              customText3,
                              style: TextStyle(
                                fontSize: 20,
                                color: textColor.withValues(alpha: 0.95),
                                fontFamily: themeService.fontFamily,
                                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 20),
                    BoxShadow(color: secondaryColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: state == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: state.songs.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withValues(alpha: 0.3)),
                        itemBuilder: (context, i) {
                          final s = state.songs[i];
                          // Alternate between primary and secondary colors for visual variety
                          final itemColor = i % 2 == 0 ? primaryColor : secondaryColor;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: itemColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: itemColor.withValues(alpha: 0.4), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              title: Text(s.title, style: TextStyle(fontSize: themeService.titleFontSize, fontWeight: FontWeight.w600, color: textColor, fontFamily: themeService.fontFamily)),
                              subtitle: s.artist != null ? Text(s.artist!, style: TextStyle(fontSize: themeService.titleFontSize * 0.65, color: textColor.withValues(alpha: 0.8), fontFamily: themeService.fontFamily)) : null,
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
                  color: cardColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 3),
                  gradient: LinearGradient(
                    colors: [primaryColor.withValues(alpha: 0.3), secondaryColor.withValues(alpha: 0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
                    BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
                  ],
                ),
                child: Text('$minutes:$seconds', style: TextStyle(fontSize: themeService.timerFontSize, fontWeight: FontWeight.w900, color: accentColor, fontFamily: themeService.fontFamily, shadows: [Shadow(color: primaryColor, blurRadius: 15)])),
              ),
            ),
          ]),
        ),
        // Winning song dialog overlay - on top of everything
        if (_showWinningDialog && _winningSong != null)
          _winningSongDialog(),
      ]),
    );
  }

  Widget _winningSongDialog() {
    if (_winningSong == null) return const SizedBox.shrink();
    
    final bgColor = _parseColor(themeService.backgroundColor);
    final accentColor = _parseColor(themeService.accentColor);
    
    return Container(
      color: bgColor.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 80, color: _getTextColorForBackground(accentColor)),
              const SizedBox(height: 24),
              Text(
                'WINNING SONG!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _getTextColorForBackground(accentColor),
                  fontFamily: themeService.fontFamily,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _winningSong!.title,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getTextColorForBackground(accentColor),
                  fontFamily: themeService.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
              if (_winningSong!.artist != null) ...[
                const SizedBox(height: 12),
                Text(
                  _winningSong!.artist!,
                  style: TextStyle(
                    fontSize: 28,
                    color: _getTextColorForBackground(accentColor).withValues(alpha: 0.9),
                    fontFamily: themeService.fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _getTextColorForBackground(accentColor).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: ${_winningSong!.score}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getTextColorForBackground(accentColor),
                    fontFamily: themeService.fontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset timer to continue',
                style: TextStyle(
                  fontSize: 18,
                  color: _getTextColorForBackground(accentColor).withValues(alpha: 0.7),
                  fontFamily: themeService.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance < 0.5 ? Colors.white : Colors.black;
  }
}



