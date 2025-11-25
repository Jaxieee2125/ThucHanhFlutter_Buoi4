import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

// --- SERVICE XÁC THỰC (AUTH) ---
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream lắng nghe trạng thái đăng nhập
  Stream<User?> get user => _auth.authStateChanges();

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// --- SERVICE DỮ LIỆU (DATABASE) ---
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Biến lưu ID người dùng hiện tại (để lọc điểm)
  final String? uid;
  
  DatabaseService({this.uid});

  // 1. HÀM LẤY LỊCH HỌC (Bạn đang bị thiếu hàm này)
  Stream<List<Schedule>> getSchedules() {
    return _db.collection('schedules').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Schedule.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  Stream<List<Grade>> getGrades() {
    Query query = _db.collection('grades');

    // Nếu có UID (tức là đã đăng nhập), chỉ lấy điểm của học sinh đó
    if (uid != null) {
      // Lưu ý: Cần đảm bảo khi Giáo viên nhập điểm, trường 'studentId' phải khớp với uid của học sinh
      // Tạm thời để hiển thị demo, mình sẽ comment dòng where này lại.
      // Khi bạn đã nhập dữ liệu chuẩn, hãy mở comment ra nhé:
      
      // query = query.where('studentId', isEqualTo: uid); 
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Grade.fromFirestore(data, doc.id);
      }).toList();
    });
  }
  }