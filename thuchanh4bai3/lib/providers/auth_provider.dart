// lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream để lắng nghe trạng thái đăng nhập từ Firebase
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Getter để truy cập đối tượng User hiện tại của Firebase
  User? get currentFirebaseUser => _auth.currentUser;

  // Hàm Đăng ký (Register)
  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được sử dụng.');
      } else {
        throw Exception(e.message);
      }
    }
  }

  // Hàm Đăng nhập (Login)
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy tài khoản với email này.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không chính xác.');
      } else {
        throw Exception('Đăng nhập thất bại: ${e.message}');
      }
    }
  }

  // Hàm Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }
}
