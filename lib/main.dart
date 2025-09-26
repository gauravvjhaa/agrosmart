import 'package:agrismart/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/service_locator.dart';
import 'core/state/app_state.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ServiceLocator.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = ServiceLocator.get<AppState>();

    return AnimatedBuilder(
      animation: appState,
      builder: (_, __) {
        return MaterialApp(
          title: 'AgroSmart',
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: Typography.blackCupertino.apply(fontFamily: 'Roboto'),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: Typography.whiteCupertino.apply(fontFamily: 'Roboto'),
          ),
          themeMode: appState.themeMode,

          locale: appState.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ne')],

          onGenerateRoute: AppRouter.onGenerateRoute,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // This builder must not call anything that rebuilds its parents.
              // We schedule the state change for after the build is complete.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final user = snapshot.data;
                if (user != null) {
                  // User is logged in. Update state and fetch preferences.
                  appState.setLoggedIn(true, name: user.displayName ?? '');
                  appState.fetchAndSetUserPreferences();
                } else {
                  // User is logged out. Update state.
                  appState.setLoggedIn(false);
                }
              });

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // The UI will react based on the `loggedIn` property of AppState.
              return appState.loggedIn
                  ? const DashboardScreen()
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
