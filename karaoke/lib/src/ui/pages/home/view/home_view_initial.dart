part of 'home_view.dart';

final class _HomeViewInitial extends StatelessWidget {
  const _HomeViewInitial();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state as HomeInitialState;

    return const Center(
      child: Text('Initial State'),
    );
  }
}
