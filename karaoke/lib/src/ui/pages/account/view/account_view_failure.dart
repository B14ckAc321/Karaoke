part of 'account_view.dart';

final class _AccountViewFailure extends StatelessWidget {
  const _AccountViewFailure();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountBloc>();
    final state = bloc.state as AccountFailureState;

    return Center(
      child: Text(state.errorMessage),
    );
  }
}
