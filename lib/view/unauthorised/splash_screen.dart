// import 'package:school_desk_app/config/color/app_color.dart';
// import 'package:school_desk_app/services/splash/splash_service.dart';
// import 'package:flutter/material.dart';
// import 'package:school_desk_app/utils/extensions/text_extension.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   final SplashService _splashService = SplashService();
//   @override
//   void initState() {
//     super.initState();
//     _splashService.isLogin(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(gradient: AppColors.purpleGlowGradient),
//         child: Center(
//           child: Text(
//             'Graapes',
//             style: context.h3.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 0.4,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
