import 'package:flutter/material.dart';
import 'package:karaoke/src/repositories/song_repository.dart';
import 'package:karaoke/src/services/backend_service.dart';
import 'package:karaoke/src/services/theme_service.dart';

final class BarPage extends StatefulWidget {
  const BarPage({super.key});

  @override
  State<BarPage> createState() => _BarPageState();
}

class _BarPageState extends State<BarPage> {
  final backend = BackendService.getInstance();
  final repo = SongRepository.getInstance();
  final themeService = ThemeService.getInstance();
  final _titleCtrl = TextEditingController();

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

  // Calculate if a color is dark (returns true) or light (returns false)
  bool _isDarkColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance < 0.5;
  }

  // Get appropriate text color for a background color
  Color _getTextColorForBackground(Color backgroundColor) {
    return _isDarkColor(backgroundColor) ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(themeService.backgroundColor);
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    final buttonColor = _parseColor(themeService.buttonColor);
    final primaryColor = _parseColor(themeService.primaryColor);
    final secondaryColor = _parseColor(themeService.secondaryColor);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Bar', style: TextStyle(fontFamily: themeService.fontFamily)),
        backgroundColor: cardColor,
        foregroundColor: textColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _addSongForm(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: secondaryColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final state = backend.state;
                  final searchQuery = _titleCtrl.text.trim().toLowerCase();
                  
                  // Filter songs by search query if there's a search
                  final displaySongs = searchQuery.isEmpty 
                    ? (state?.songs ?? [])
                    : (state?.songs.where(
                        (s) => s.title.toLowerCase().contains(searchQuery) || 
                               (s.artist != null && s.artist!.toLowerCase().contains(searchQuery))
                      ).toList() ?? []);
                  
                  if (state == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return ListView.separated(
                    itemCount: displaySongs.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withValues(alpha: 0.3)),
                    itemBuilder: (context, i) {
                      final s = displaySongs[i];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor, fontFamily: themeService.fontFamily)),
                                if (s.artist != null) Text(s.artist!, style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7), fontFamily: themeService.fontFamily)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)),
                                child: Text('${s.score}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: bgColor, fontFamily: themeService.fontFamily)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 12, runSpacing: 12, children: [
                              ElevatedButton(
                                onPressed: () => repo.updateScore(s.id, delta: -5),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: _getTextColorForBackground(buttonColor),
                                ),
                                child: const Text('-5'),
                              ),
                              ElevatedButton(
                                onPressed: () => repo.updateScore(s.id, delta: -1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: _getTextColorForBackground(buttonColor),
                                ),
                                child: const Text('-1'),
                              ),
                              ElevatedButton(
                                onPressed: () => repo.updateScore(s.id, delta: 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: _getTextColorForBackground(buttonColor),
                                ),
                                child: const Text('+1'),
                              ),
                              ElevatedButton(
                                onPressed: () => repo.updateScore(s.id, delta: 5),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: _getTextColorForBackground(buttonColor),
                                ),
                                child: const Text('+5'),
                              ),
                              ElevatedButton(
                                onPressed: () => repo.updateScore(s.id, delta: 10),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: _getTextColorForBackground(buttonColor),
                                ),
                                child: const Text('+10'),
                              ),
                            ]),
                          ]),
                        );
                      },
                    );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _addSongForm() {
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final buttonColor = _parseColor(themeService.buttonColor);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Song', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: themeService.fontFamily)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              style: TextStyle(color: textColor, fontFamily: themeService.fontFamily),
              decoration: InputDecoration(
                labelText: 'Song name',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: buttonColor)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return;
              await repo.addSong(title: title);
              _titleCtrl.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: _getTextColorForBackground(buttonColor),
            ),
            child: const Text('Add'),
          ),
        ]),
      ]),
    );
  }
}



