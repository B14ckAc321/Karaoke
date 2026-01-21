import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karaoke/src/navigation/routes.dart';
import 'package:karaoke/src/repositories/song_repository.dart';
import 'package:karaoke/src/services/backend_service.dart';
import 'package:karaoke/src/services/theme_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

final class DjPage extends StatefulWidget {
  const DjPage({super.key});

  @override
  State<DjPage> createState() => _DjPageState();
}

class _DjPageState extends State<DjPage> {
  final backend = BackendService.getInstance();
  final repo = SongRepository.getInstance();
  final themeService = ThemeService.getInstance();

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1'); // Duration in minutes
  SongModel? _winningSong; // Track winning song separately

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
    final state = backend.state;
    final timer = state?.timer;
    final minutes = timer != null ? (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0') : '--';
    final seconds = timer != null ? (timer.remainingSeconds % 60).toString().padLeft(2, '0') : '--';
    final bgColor = _parseColor(themeService.backgroundColor);
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('DJ', style: TextStyle(fontFamily: themeService.fontFamily)),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(RouteNames.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Column(children: [
              _addSongForm(),
              const SizedBox(height: 12),
              Expanded(child: _songsList()),
            ])),
            const SizedBox(width: 16),
            SizedBox(
              width: 360,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('$minutes:$seconds', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: accentColor, fontFamily: themeService.fontFamily)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _durationCtrl,
                    style: TextStyle(color: textColor, fontFamily: themeService.fontFamily),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withValues(alpha: 0.5))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _parseColor(themeService.buttonColor))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ElevatedButton(
                      onPressed: () {
                        final minutes = int.tryParse(_durationCtrl.text) ?? 1;
                        repo.controlTimer('start', durationSeconds: minutes * 60); // Convert minutes to seconds
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _parseColor(themeService.buttonColor),
                        foregroundColor: _getTextColorForBackground(_parseColor(themeService.buttonColor)),
                      ),
                      child: const Text('Start'),
                    ),
                    ElevatedButton(
                      onPressed: () => repo.controlTimer('stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _parseColor(themeService.buttonColor),
                        foregroundColor: _getTextColorForBackground(_parseColor(themeService.buttonColor)),
                      ),
                      child: const Text('Stop'),
                    ),
                    ElevatedButton(
                      onPressed: () => repo.controlTimer('reset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _parseColor(themeService.buttonColor),
                        foregroundColor: _getTextColorForBackground(_parseColor(themeService.buttonColor)),
                      ),
                      child: const Text('Reset'),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
        // Info panel (bottom right)
        Positioned(
          bottom: 16,
          right: 16,
          child: _infoPanel(),
        ),
        // Winning song card (bottom right, above info panel) - shows when timer ends
        if (_winningSong != null)
          Positioned(
            bottom: 140, // Position above info panel (info panel is ~120px + 20px spacing)
            right: 16,
            child: _winningSongCard(),
          ),
      ]),
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
              _titleCtrl.clear(); _artistCtrl.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _parseColor(themeService.buttonColor),
              foregroundColor: _getTextColorForBackground(_parseColor(themeService.buttonColor)),
            ),
            child: const Text('Add'),
          ),
        ]),
      ]),
    );
  }

  Widget _songsList() {
    final state = backend.state;
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    final bgColor = _parseColor(themeService.backgroundColor);
    final buttonColor = _parseColor(themeService.buttonColor);
    final primaryColor = _parseColor(themeService.primaryColor);
    final secondaryColor = _parseColor(themeService.secondaryColor);
    
    // Filter out winning song from main list
    final regularSongs = state?.songs.where((s) => s.id != _winningSong?.id).toList() ?? [];
    
    return Container(
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
          
          // Filter out winning song and apply search filter
          var filteredSongs = regularSongs;
          if (searchQuery.isNotEmpty) {
            filteredSongs = regularSongs.where(
              (s) => s.title.toLowerCase().contains(searchQuery) || 
                     (s.artist != null && s.artist!.toLowerCase().contains(searchQuery))
            ).toList();
          }
          
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.separated(
            itemCount: filteredSongs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withValues(alpha: 0.3)),
            itemBuilder: (context, i) {
              final s = filteredSongs[i];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(s.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor, fontFamily: themeService.fontFamily)),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: textColor.withValues(alpha: 0.7)),
                            onPressed: () async {
                              final titleCtrl = TextEditingController(text: s.title);
                              final artistCtrl = TextEditingController(text: s.artist ?? '');
                              final result = await showDialog<Map<String, String>?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Song'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: titleCtrl,
                                        decoration: const InputDecoration(labelText: 'Title'),
                                        autofocus: true,
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: artistCtrl,
                                        decoration: const InputDecoration(labelText: 'Artist (optional)'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, {
                                        'title': titleCtrl.text.trim(),
                                        'artist': artistCtrl.text.trim(),
                                      }),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null && result['title']?.isNotEmpty == true) {
                                await repo.updateSong(id: s.id, title: result['title'], artist: result['artist']?.isEmpty == true ? null : result['artist']);
                              }
                            },
                            tooltip: 'Edit title',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ]),
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
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Song'),
                              content: Text('Remove "${s.title}" from the list?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) await repo.deleteSong(s.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete'),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          final q = Uri.encodeComponent('${s.title} ${s.artist ?? ''} karaoke');
                          launchUrlString('https://www.youtube.com/results?search_query=$q', mode: LaunchMode.externalApplication);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: buttonColor),
                        ),
                        child: const Text('Search karaoke'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final ctrl = TextEditingController(text: s.youtubeUrl ?? '');
                          final value = await showDialog<String?>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('YouTube URL'),
                              content: TextField(controller: ctrl),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()), child: const Text('Save')),
                              ],
                            ),
                          );
                          if (value != null) await repo.setYoutubeUrl(id: s.id, youtubeUrl: value);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: buttonColor),
                        ),
                        child: const Text('Set URL'),
                      ),
                    ]),
                  ]),
                );
              },
            );
        },
      ),
    );
  }

  Widget _infoPanel() {
    final state = backend.state;
    final timer = state?.timer;
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    
    // Find winning song (highest score)
    SongModel? winningSong;
    if (state != null && state.songs.isNotEmpty) {
      winningSong = state.songs.reduce((a, b) => a.score > b.score ? a : b);
    }
    
    final timerEnded = timer != null && timer.remainingSeconds == 0;
    
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: timerEnded ? accentColor.withValues(alpha: 0.9) : cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: timerEnded ? accentColor : accentColor.withValues(alpha: 0.3), 
          width: timerEnded ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: timerEnded ? accentColor.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.2), 
            blurRadius: timerEnded ? 15 : 8, 
            spreadRadius: timerEnded ? 3 : 2
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              timerEnded ? Icons.emoji_events : Icons.music_note, 
              size: 18, 
              color: timerEnded ? _getTextColorForBackground(accentColor) : accentColor
            ),
            const SizedBox(width: 6),
            Text(
              timerEnded ? 'WINNING SONG' : 'Current Leader',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: timerEnded ? _getTextColorForBackground(accentColor) : accentColor,
                fontFamily: themeService.fontFamily,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (winningSong != null) ...[
            Text(
              winningSong.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: timerEnded ? _getTextColorForBackground(accentColor) : textColor,
                fontFamily: themeService.fontFamily,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (winningSong.artist != null) ...[
              const SizedBox(height: 4),
              Text(
                winningSong.artist!,
                style: TextStyle(
                  fontSize: 12,
                  color: timerEnded 
                    ? _getTextColorForBackground(accentColor).withValues(alpha: 0.8) 
                    : textColor.withValues(alpha: 0.7),
                  fontFamily: themeService.fontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: timerEnded 
                  ? _getTextColorForBackground(accentColor).withValues(alpha: 0.2)
                  : accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Score: ${winningSong.score}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: timerEnded ? _getTextColorForBackground(accentColor) : accentColor,
                  fontFamily: themeService.fontFamily,
                ),
              ),
            ),
          ] else
            Text(
              'No songs yet',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
                fontFamily: themeService.fontFamily,
              ),
            ),
        ],
      ),
    );
  }

  Widget _winningSongCard() {
    if (_winningSong == null) return const SizedBox.shrink();
    
    final s = _winningSong!;
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    final bgColor = _parseColor(themeService.backgroundColor);
    final buttonColor = _parseColor(themeService.buttonColor);
    final primaryColor = _parseColor(themeService.primaryColor);
    
    return Container(
      width: 350,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor, width: 3),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
          BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.emoji_events, color: accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'WINNING SONG',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontFamily: themeService.fontFamily,
              ),
            ),
          ]),
          const SizedBox(height: 8),
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
          if (s.youtubeUrl != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrlString(s.youtubeUrl!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Open YouTube'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: buttonColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



