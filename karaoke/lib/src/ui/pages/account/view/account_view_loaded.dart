part of 'account_view.dart';

final class _AccountViewLoaded extends StatelessWidget {
  const _AccountViewLoaded();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountBloc>();
    final state = bloc.state as AccountLoadedState;

    return const Center(
      child: Text('Loaded State'),
    );
  }
}
