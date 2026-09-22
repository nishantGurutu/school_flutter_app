import 'dart:async';
import 'package:flutter/material.dart';
import 'package:school_desk_app/config/routes/routes_name.dart';

class SplashService {
  void isLogin(BuildContext context) {
    Timer(
      const Duration(seconds: 2),
      () => Navigator.pushNamedAndRemoveUntil(
        context,
        RoutesName.bottom_bar,
        (route) => false,
      ),
    );
  }
}
