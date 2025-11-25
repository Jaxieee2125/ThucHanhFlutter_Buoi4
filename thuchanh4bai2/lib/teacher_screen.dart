import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'services.dart'; // Để dùng hàm signOut

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _subjectController = TextEditingController();
  final _scoreController = TextEditingController();
  final _studentIdController = TextEditingController(); // Nhập ID học sinh cần cho điểm (thực tế nên là dropdown)
  bool _isLoading = false;

  Future<void> _addGrade() async {
    if (_subjectController.text.isEmpty || _scoreController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      // Thêm điểm vào collection 'grades'
      await FirebaseFirestore.instance.collection('grades').add({
        'subject': _subjectController.text,
        'score': double.tryParse(_scoreController.text) ?? 0.0,
        'type': 'Giữa kỳ', // Ví dụ mặc định
        'studentId': _studentIdController.text, // Cần trường này để biết điểm của ai
        'teacherId': 'ID_CUA_GIAO_VIEN', // Lấy từ Auth
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nhập điểm thành công!")));
      _subjectController.clear();
      _scoreController.clear();
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Giáo Viên Dashboard"),
        backgroundColor: Colors.orange, // Màu khác để dễ phân biệt
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nhập điểm cho học sinh", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(labelText: "Mã học sinh (Email hoặc ID)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: "Môn học", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Điểm số", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addGrade,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isLoading ? const CircularProgressIndicator() : const Text("Lưu Điểm"),
              ),
            ),
            
            const Divider(height: 40),
            const Text("Danh sách điểm đã nhập gần đây:", style: TextStyle(fontSize: 16)),
            // Có thể thêm StreamBuilder ở đây để giáo viên xem lại lịch sử nhập điểm
          ],
        ),
      ),
    );
  }
}