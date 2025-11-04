part of 'home_view.dart';

final class _HomeViewLoaded extends StatelessWidget {
  const _HomeViewLoaded();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state as HomeLoadedState;

    return const Center(
      child: Text('Loaded State'),
    );
  }
}
