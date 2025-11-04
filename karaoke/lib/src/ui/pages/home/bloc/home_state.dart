part of 'home_bloc.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeInitialState extends HomeState {}

final class HomeLoadingState extends HomeState {}

final class HomeLoadedState extends HomeState {}

final class HomeFailureState extends HomeState {

  const HomeFailureState({required this.errorMessage});
  final String errorMessage;
}
