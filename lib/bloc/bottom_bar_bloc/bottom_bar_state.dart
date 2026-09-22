part of 'bottom_bar_bloc.dart';

class BottomBarState {
  final int currentIndex;

  BottomBarState({this.currentIndex = 0});

  BottomBarState copyWith({int? currentIndex}) {
    return BottomBarState(currentIndex: currentIndex ?? this.currentIndex);
  }
}
