part of 'account_bloc.dart';

sealed class AccountState {
  const AccountState();
}

final class AccountInitialState extends AccountState {}

final class AccountLoadingState extends AccountState {}

final class AccountLoadedState extends AccountState {}

final class AccountFailureState extends AccountState {

  const AccountFailureState({required this.errorMessage});
  final String errorMessage;
}
