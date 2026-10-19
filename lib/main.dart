import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_desk_app/services/push_notifications.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/routes.dart' as new_routes;
import 'core/routes/routes_name.dart';
import 'core/di/locator.dart';
import 'firebase/notification_firebase.dart';
import 'firebase/notification_services.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/school/school_bloc.dart';
import 'location_tracking/presentation/bloc/location_tracking_bloc.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotifications.instance.initialize();
  setupLocator();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await LocalNotificationService.initialize();
    await firebaseNotification();
  } catch (e) {
    debugPrint("Firebase & Notification setup error: $e");
  }
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
            BlocProvider<LocationTrackingBloc>(
              create: (_) => LocationTrackingBloc(),
            ),
            BlocProvider<SchoolBloc>(create: (_) => SchoolBloc()),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'SchoolDesk',
            theme: AppTheme.lightTheme,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            initialRoute: RoutesName.splash,
            onGenerateRoute: new_routes.Routes.generateRoute,
          ),
        );
      },
    );
  }
}
