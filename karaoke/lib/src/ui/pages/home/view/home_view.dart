import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:karaoke/l10n/gen/app_localizations.dart';
import 'package:karaoke/src/ui/pages/home/bloc/home_bloc.dart';


part 'home_view_initial.dart';
part 'home_view_loading.dart';
part 'home_view_loaded.dart';
part 'home_view_failure.dart';

final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(HomeInitEvent()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, HomeState state) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.homePage_title),
          ),
          body: _getBody(state, context),
        ),
      ),
    );
  }

  Widget _getBody(HomeState state, BuildContext context) {
    switch (state) {
      case HomeInitialState(): return const _HomeViewInitial();
      case HomeLoadingState(): return const _HomeViewLoading();
      case HomeLoadedState(): return const _HomeViewLoaded();
      case HomeFailureState(): return const _HomeViewFailure();
    }
  }
}
