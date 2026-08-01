import 'package:admin_dashboard/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'constants/custome_theme.dart';
import 'helpers/all_routes.dart';
import 'helpers/di.dart';
import 'helpers/navigation_service.dart';
import 'networks/dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  diSetup();
  DioSingleton.instance.create();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Bloom Admin Dashboard',
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: CustomTheme.kToDark,
            scaffoldBackgroundColor: const Color(0xFF0D0F1D),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF14172D),
              elevation: 0,
            ),
          ),
          debugShowCheckedModeBanner: false,
          navigatorKey: NavigationService.navigatorKey,
          onGenerateRoute: RouteGenerator.generateRoute,
          home: const Loading(),
        );
      },
    );
  }
}
