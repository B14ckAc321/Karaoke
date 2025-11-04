import 'package:flutter/material.dart';
import 'package:karaoke/src/services/backend_service.dart';

final class TvPage extends StatefulWidget {
  const TvPage({super.key});

  @override
  State<TvPage> createState() => _TvPageState();
}

class _TvPageState extends State<TvPage> {
  final backend = BackendService.getInstance();

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
      backgroundColor: const Color(0xFF0b0f1a),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Karaoke', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(16)),
              child: state == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: state.songs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white24),
                      itemBuilder: (context, i) {
                        final s = state.songs[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          title: Text(s.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                          subtitle: s.artist != null ? Text(s.artist!, style: const TextStyle(fontSize: 18)) : null,
                          trailing: Text('${s.score}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF11182b), borderRadius: BorderRadius.circular(12)),
              child: Text('$minutes:$seconds', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}



