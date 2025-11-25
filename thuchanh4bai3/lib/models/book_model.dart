// lib/models/book_model.dart
class BookModel {
  final String id;
  final String tenSach;
  final String tacGia;
  final String moTa;
  final String anhBiaUrl;
  String trangThai; // 'Con' hoặc 'Het'
  final String theLoai;

  BookModel({
    required this.id,
    required this.tenSach,
    required this.tacGia,
    required this.moTa,
    required this.anhBiaUrl,
    required this.trangThai,
    required this.theLoai,
  });
}
