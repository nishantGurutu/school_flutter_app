import 'package:flutter_bloc/flutter_bloc.dart';

part 'bottom_bar_event.dart';
part 'bottom_bar_state.dart';

class BottomBarBloc extends Bloc<BottomBarEvent, BottomBarState> {
  BottomBarBloc() : super(BottomBarState()) {
    on<BottomBarTabChanged>((event, emit) {
      emit(state.copyWith(currentIndex: event.index));
    });
  }
}
