// lib/models/user_model.dart
class UserModel {
  final String id;
  final String ten;
  final String email;
  final String vaiTro; // 'NguoiDung' hoặc 'ThuThu'

  UserModel({
    required this.id,
    required this.ten,
    required this.email,
    required this.vaiTro,
  });
}
