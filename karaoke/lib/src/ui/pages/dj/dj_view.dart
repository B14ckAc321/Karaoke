import 'package:flutter/material.dart';
import 'package:karaoke/src/repositories/song_repository.dart';
import 'package:karaoke/src/services/backend_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

final class DjPage extends StatefulWidget {
  const DjPage({super.key});

  @override
  State<DjPage> createState() => _DjPageState();
}

class _DjPageState extends State<DjPage> {
  final backend = BackendService.getInstance();
  final repo = SongRepository.getInstance();

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');

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
    final timer = state?.timer;
    final minutes = timer != null ? (timer.remainingSeconds ~/ 60).toString().padLeft(2, '0') : '--';
    final seconds = timer != null ? (timer.remainingSeconds % 60).toString().padLeft(2, '0') : '--';
    return Scaffold(
      appBar: AppBar(title: const Text('DJ')),
      body: Padding(
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
              decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('$minutes:$seconds', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Duration (sec)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ElevatedButton(onPressed: () => repo.controlTimer('start', durationSeconds: int.tryParse(_durationCtrl.text)), child: const Text('Start')),
                  ElevatedButton(onPressed: () => repo.controlTimer('stop'), child: const Text('Stop')),
                  ElevatedButton(onPressed: () => repo.controlTimer('reset'), child: const Text('Reset')),
                ]),
              ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Song', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Song name'))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final title = _titleCtrl.text.trim();
              if (title.isEmpty) return;
              await repo.addSong(title: title);
              _titleCtrl.clear(); _artistCtrl.clear();
            },
            child: const Text('Add'),
          ),
        ]),
      ]),
    );
  }

  Widget _songsList() {
    final state = backend.state;
    return Container(
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
                      OutlinedButton(
                        onPressed: () {
                          final q = Uri.encodeComponent('${s.title} ${s.artist ?? ''} karaoke');
                          launchUrlString('https://www.youtube.com/results?search_query=$q', mode: LaunchMode.externalApplication);
                        },
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
                        child: const Text('Set URL'),
                      ),
                      ElevatedButton(
                        onPressed: s.youtubeUrl != null ? () => launchUrlString(s.youtubeUrl!, mode: LaunchMode.externalApplication) : null,
                        child: const Text('Open YouTube'),
                      ),
                    ]),
                  ]),
                );
              },
            ),
    );
  }
}



