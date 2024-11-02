import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'menu_page.dart';

// TODO: * Add device monitoring and alerts for temp and cpu
// TODO: * Add Stay awake and also for camera
// TODO: Add option to hide camera preview (disabled right now)
// TODO: Upload runner pictures

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://wsetfdxsozntgoadtxss.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzZXRmZHhzb3pudGdvYWR0eHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwNTA3MDQsImV4cCI6MjA0NTYyNjcwNH0.zMfFyiMjRkhKrWiFsRltwZ8HB5sIgI1FJe_Mud4zO0o"
  );

  runApp(const MyApp());
}

void goToRoute(BuildContext context, Widget routeWidget) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => routeWidget));
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 157, 157)),
        useMaterial3: true,
      ),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : const MenuPage(),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}