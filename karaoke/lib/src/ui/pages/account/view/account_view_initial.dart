part of 'account_view.dart';

final class _AccountViewInitial extends StatelessWidget {
  const _AccountViewInitial();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountBloc>();
    final state = bloc.state as AccountInitialState;

    return const Center(
      child: Text('Initial State'),
    );
  }
}
