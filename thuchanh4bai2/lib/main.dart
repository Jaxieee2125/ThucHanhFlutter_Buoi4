// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'teacher_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services.dart';
import 'login_screen.dart';
import 'feature_screens.dart';
import 'profile_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const SchoolApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Tin nhắn nhận được khi tắt app: ${message.messageId}");
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp AuthService và DatabaseService cho toàn bộ app
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        // StreamProvider lắng nghe user đăng nhập/đăng xuất
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
         ProxyProvider<User?, DatabaseService>(
          update: (_, user, __) => DatabaseService(uid: user?.uid),
        ),
      ],
      
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quản Lý Trường Học',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Widget điều hướng dựa trên trạng thái đăng nhập
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);

    // 1. Chưa đăng nhập -> Về trang Login
    if (firebaseUser == null) {
      return const LoginScreen();
    }

    // 2. Đã đăng nhập -> Lắng nghe luồng dữ liệu từ Firestore (StreamBuilder)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots(), // Dùng snapshots() để lắng nghe thay đổi
      builder: (context, snapshot) {
        // Đang tải dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Có lỗi xảy ra
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Lỗi tải dữ liệu người dùng!"),
                  ElevatedButton(
                    onPressed: () => context.read<AuthService>().signOut(),
                    child: const Text("Đăng xuất"),
                  )
                ],
              ),
            ),
          );
        }

        // Dữ liệu tồn tại -> Kiểm tra Role
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'student';

          if (role == 'teacher') {
            return const TeacherDashboard();
          } else {
            return const MainScreen();
          }
        }

        // Trường hợp: Đã có tài khoản Auth nhưng chưa có dữ liệu trong Firestore
        // (Đây là chỗ bạn đang bị kẹt, giờ thêm nút Đăng xuất để thoát ra)
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đang thiết lập tài khoản..."),
                const SizedBox(height: 20),
                const Text("Nếu đợi quá lâu, hãy thử đăng nhập lại."),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  child: const Text("Quay lại màn hình Đăng nhập"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Màn hình chính chứa BottomNavigationBar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
    @override
  void initState() {
    super.initState();
    setupFCM();
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Xin quyền nhận thông báo
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Người dùng đã cấp quyền thông báo');
      
      // 2. Lấy Token (Dùng token này để test gửi tin từ Firebase Console)
      String? token = await messaging.getToken();
      print("FCM Token của máy này: $token");
      
      // 3. Lắng nghe tin nhắn khi app đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Nhận tin nhắn khi đang mở app: ${message.notification?.title}');
        
        // Hiện thông báo dạng Dialog hoặc SnackBar
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(message.notification?.title ?? "Thông báo mới"),
            content: Text(message.notification?.body ?? ""),
          ),
        );
      });
    }
  }

  // Danh sách các màn hình con
  final List<Widget> _screens = [
    const Center(child: Text("Trang chủ - Thông báo")), // Placeholder cho Home
    const ScheduleScreen(),
    const GradesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Học sinh Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Cố định vị trí (quan trọng khi có >3 items)
        backgroundColor: Colors.white,       // Màu nền của thanh
        selectedItemColor: Colors.blue,      // Màu của item đang chọn
        unselectedItemColor: Colors.grey,    // Màu của item KHÔNG chọn
        showUnselectedLabels: true,          // Luôn hiện chữ bên dưới
        elevation: 5,                        // Đổ bóng cho rõ ranh giới
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Lịch học"),
          BottomNavigationBarItem(icon: Icon(Icons.score), label: "Điểm số"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
        ],
      ),
    );
  }
}