import 'package:bloggers/Screens/SplashScreen.dart';
import 'package:bloggers/Screens/SetNewPasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color bloggerOrange = Color(0xFFEB740C);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yeofznmvlfuoyuejhgzl.supabase.co',
    anonKey: 'sb_publishable_cTG0uhvWuWO5MdxbGczA_g_vMQbRAfX',
  );


  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;

    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: bloggerOrange,
        colorScheme: ColorScheme.fromSeed(seedColor: bloggerOrange),
        useMaterial3: true,
      ),
      home: const Splashscreen(),
    );
  }
}