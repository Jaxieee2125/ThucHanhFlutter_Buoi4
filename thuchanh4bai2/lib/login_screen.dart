import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller cho ô nhập liệu
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  
  // Trạng thái màn hình
  bool _isLogin = true; // true: Đang ở màn hình Đăng nhập, false: Đăng ký
  bool _isLoading = false;
  
  // Role mặc định khi đăng ký
  String _selectedRole = 'student'; 

  final _auth = FirebaseAuth.instance;

  // Hàm xử lý chung cho cả Đăng nhập và Đăng ký
  Future<void> _submitAuthForm() async {
    // 1. Kiểm tra Form
    if (!_formKey.currentState!.validate()) {
      print("Form chưa hợp lệ (chưa nhập email hoặc pass ngắn)");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      print("--- BẮT ĐẦU XỬ LÝ ---");
      print("Email: ${_emailController.text.trim()}");
      print("Role đang chọn: $_selectedRole");

      if (_isLogin) {
        // Đăng nhập
        print("Đang thực hiện Đăng nhập...");
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
        print("Đăng nhập thành công!");
      } else {
        // Đăng ký
        print("Đang thực hiện Đăng ký Auth...");
        UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
        
        print("Đăng ký Auth thành công! UID: ${userCred.user!.uid}");
        print("Đang lưu vào Firestore...");

        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'createdAt': DateTime.now().toIso8601String(),
        });
        print("Lưu Firestore thành công!");
      }
      
    } on FirebaseAuthException catch (e) {
      // IN LỖI RA CONSOLE ĐỂ BẠN ĐỌC
      print("--- LỖI FIREBASE AUTH ---");
      print("Mã lỗi: ${e.code}");
      print("Chi tiết: ${e.message}");
      
      String message = "Đã xảy ra lỗi: ${e.message}";
      if (e.code == 'email-already-in-use') message = "Email này đã có người dùng!";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("--- LỖI KHÁC ---");
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? "Đăng Nhập" : "Đăng Ký Tài Khoản"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo hoặc Icon
                Icon(
                  _isLogin ? Icons.lock_open : Icons.person_add,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                // Ô nhập Email
                TextFormField(
                  controller: _emailController,
                  key: const ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (val) {
                    if (val == null || !val.contains('@')) {
                      return "Vui lòng nhập email hợp lệ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Ô nhập Password
                TextFormField(
                  controller: _passController,
                  key: const ValueKey('password'),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return "Mật khẩu phải từ 6 ký tự trở lên";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // --- PHẦN CHỌN ROLE (CHỈ HIỆN KHI ĐĂNG KÝ) ---
                if (!_isLogin)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Row(
                              children: [Icon(Icons.school), SizedBox(width: 10), Text("Học sinh")],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Row(
                              children: [Icon(Icons.person_outline), SizedBox(width: 10), Text("Giáo viên")],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'parent',
                            child: Row(
                              children: [Icon(Icons.family_restroom), SizedBox(width: 10), Text("Phụ huynh")],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Nút Submit
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitAuthForm,
                      child: Text(
                        _isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Nút chuyển đổi Login <-> Register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin; // Đảo ngược trạng thái
                      _formKey.currentState!.reset(); // Xóa các ô nhập liệu
                    });
                  },
                  child: Text(_isLogin
                      ? "Chưa có tài khoản? Tạo mới ngay"
                      : "Đã có tài khoản? Đăng nhập"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}