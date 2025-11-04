import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_event.dart';
part 'account_state.dart';

final class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc() : super(AccountInitialState()) {
    on<AccountInitEvent>(_initEvent);
  }

  Future<void> _initEvent(AccountInitEvent event, Emitter<AccountState> emit) async {
    emit(AccountLoadingState());
    // Simulate a repository network call or some initialization logic
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(AccountLoadedState());
  }
}
