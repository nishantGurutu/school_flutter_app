import 'package:flutter/material.dart';
import 'package:school_desk_app/config/routes/routes_name.dart';
import 'package:school_desk_app/view/authorised/bottom_bar/bottom_bar_screen.dart';
import 'package:school_desk_app/view/authorised/category/category_screen.dart';
import 'package:school_desk_app/view/authorised/home/home_screen.dart';
import 'package:school_desk_app/view/screens/splash_screen.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splash:
        return MaterialPageRoute(
          builder: (BuildContext context) => const SplashScreen(),
        );

      case RoutesName.bottom_bar:
        return MaterialPageRoute(
          builder: (BuildContext context) => const BottomBarScreen(),
        );

      case RoutesName.home:
        return MaterialPageRoute(
          builder: (BuildContext context) => const HomeScreen(),
        );

      case RoutesName.category:
        return MaterialPageRoute(
          builder: (BuildContext context) => const CategoryScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) {
            return const Scaffold(
              body: Center(child: Text('No route defined')),
            );
          },
        );
    }
  }
}
