part of 'home_view.dart';

final class _HomeViewLoaded extends StatefulWidget {
  const _HomeViewLoaded();

  @override
  State<_HomeViewLoaded> createState() => _HomeViewLoadedState();
}

class _HomeViewLoadedState extends State<_HomeViewLoaded> {
  final backend = BackendService.getInstance();
  final repo = SongRepository.getInstance();

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choose role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          ElevatedButton(onPressed: () => context.go(RouteNames.tv), child: const Text('TV Display')),
          ElevatedButton(onPressed: () => context.go(RouteNames.dj), child: const Text('DJ Console')),
          ElevatedButton(onPressed: () => context.go(RouteNames.bar), child: const Text('Bar Console')),
        ]),
      ]),
    );
  }
}
