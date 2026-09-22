part of 'bottom_bar_bloc.dart';

sealed class BottomBarEvent {}

class BottomBarTabChanged extends BottomBarEvent {
  final int index;
  BottomBarTabChanged(this.index);
}
