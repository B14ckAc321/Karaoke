part of 'home_view.dart';

final class _HomeViewLoading extends StatelessWidget {
  const _HomeViewLoading();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state as HomeLoadingState;

    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}
