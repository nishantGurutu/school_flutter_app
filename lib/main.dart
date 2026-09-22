import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/routes.dart' as new_routes;
import 'core/routes/routes_name.dart';
import 'core/di/locator.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/school/school_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
            BlocProvider<SchoolBloc>(create: (_) => SchoolBloc()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SchoolDesk',
            theme: AppTheme.lightTheme,
            initialRoute: RoutesName.splash,
            onGenerateRoute: new_routes.Routes.generateRoute,
          ),
        );
      },
    );
  }
}
