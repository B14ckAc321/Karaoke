import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karaoke/src/navigation/routes.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = backend.state;
    final bgColor = _parseColor(themeService.backgroundColor);
    final cardColor = _parseColor(themeService.cardColor);
    final textColor = _parseColor(themeService.textColor);
    final accentColor = _parseColor(themeService.accentColor);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Bar', style: TextStyle(fontFamily: themeService.fontFamily)),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _addSongForm(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: state == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: state.songs.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: textColor.withOpacity(0.3)),
                      itemBuilder: (context, i) {
                        final s = state.songs[i];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor, fontFamily: themeService.fontFamily)),
                                if (s.artist != null) Text(s.artist!, style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7), fontFamily: themeService.fontFamily)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)),
                                child: Text('${s.score}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: bgColor, fontFamily: themeService.fontFamily)),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 12, runSpacing: 12, children: [
                              ElevatedButton(onPressed: () => repo.updateScore(s.id, delta: -5), child: const Text('-5')),
                              ElevatedButton(onPressed: () => repo.updateScore(s.id, delta: -1), child: const Text('-1')),
                              ElevatedButton(onPressed: () => repo.updateScore(s.id, delta: 1), child: const Text('+1')),
                              ElevatedButton(onPressed: () => repo.updateScore(s.id, delta: 5), child: const Text('+5')),
                              ElevatedButton(onPressed: () => repo.updateScore(s.id, delta: 10), child: const Text('+10')),
                            ]),
                          ]),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Song name'))),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            await repo.addSong(title: title);
            _titleCtrl.clear();
          },
          child: const Text('Add'),
        ),
      ]),
    );
  }
}



