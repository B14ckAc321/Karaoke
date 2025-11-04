part of 'account_view.dart';

final class _AccountViewLoading extends StatelessWidget {
  const _AccountViewLoading();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountBloc>();
    final state = bloc.state as AccountLoadingState;

    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}
