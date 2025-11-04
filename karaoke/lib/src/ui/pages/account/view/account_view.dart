import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/ui/pages/account/bloc/account_bloc.dart';


part 'account_view_initial.dart';
part 'account_view_loading.dart';
part 'account_view_loaded.dart';
part 'account_view_failure.dart';

final class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountBloc()..add(AccountInitEvent()),
      child: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, AccountState state) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.accountPage_title),
          ),
          body: _getBody(state, context),
        ),
      ),
    );
  }

  Widget _getBody(AccountState state, BuildContext context) {
    switch (state) {
      case AccountInitialState(): return const _AccountViewInitial();
      case AccountLoadingState(): return const _AccountViewLoading();
      case AccountLoadedState(): return const _AccountViewLoaded();
      case AccountFailureState(): return const _AccountViewFailure();
    }
  }
}
