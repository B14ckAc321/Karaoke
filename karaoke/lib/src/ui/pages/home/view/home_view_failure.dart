part of 'home_view.dart';

final class _HomeViewFailure extends StatelessWidget {
  const _HomeViewFailure();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HomeBloc>();
    final state = bloc.state as HomeFailureState;

    return Center(
      child: Text(state.errorMessage),
    );
  }
}
