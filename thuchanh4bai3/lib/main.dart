// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Yêu cầu phải có file này
import 'providers/auth_provider.dart'
    as app_auth; // Sử dụng alias để tránh xung đột
import 'providers/book_provider.dart';
import 'screens/login_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/librarian_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lí Thư Viện Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: Provider.of<app_auth.AuthProvider>(context).authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // Phân quyền TẠM THỜI dựa trên email (cần thay bằng Firestore query sau)
            final String userEmail = snapshot.data!.email ?? '';

            if (userEmail == 'librarian@demo.com') {
              return const LibrarianHomeScreen();
            } else {
              return const UserHomeScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
