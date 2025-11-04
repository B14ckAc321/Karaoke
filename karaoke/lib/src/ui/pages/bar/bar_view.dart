import 'package:flutter/material.dart';
import 'package:karaoke/src/repositories/song_repository.dart';
import 'package:karaoke/src/services/backend_service.dart';

final class BarPage extends StatefulWidget {
  const BarPage({super.key});

  @override
  State<BarPage> createState() => _BarPageState();
}

class _BarPageState extends State<BarPage> {
  final backend = BackendService.getInstance();
  final repo = SongRepository.getInstance();
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    backend.addListener(_onUpdate);
  }

  @override
  void dispose() {
    backend.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final state = backend.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Bar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _addSongForm(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(12)),
              child: state == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: state.songs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white24),
                      itemBuilder: (context, i) {
                        final s = state.songs[i];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                                if (s.artist != null) Text(s.artist!, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                              ])),
                              Text('${s.score}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(12)),
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



