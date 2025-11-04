import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitialState()) {
    on<HomeInitEvent>(_initEvent);
  }

  Future<void> _initEvent(HomeInitEvent event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(HomeLoadedState());
  }
}
