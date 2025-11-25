import '../models/user_model.dart';
import '../models/book_model.dart';
import '../models/loan_model.dart';

// --- Dữ liệu người dùng ---
List<UserModel> mockUsers = [
  UserModel(
    id: 'u1',
    ten: 'Alice User',
    email: 'user@demo.com',
    vaiTro: 'NguoiDung',
  ),
  UserModel(
    id: 'u2',
    ten: 'Bob Librarian',
    email: 'librarian@demo.com',
    vaiTro: 'ThuThu',
  ),
];

// --- Dữ liệu sách ---
List<BookModel> mockBooks = [
  BookModel(
    id: 'b1',
    tenSach: 'Lập trình Flutter',
    tacGia: 'Tác giả A',
    moTa: 'Sách về Flutter và Dart.',
    anhBiaUrl: 'url_a',
    trangThai: 'Con',
    theLoai: 'Công nghệ',
  ),
  BookModel(
    id: 'b2',
    tenSach: 'Kiến trúc Clean',
    tacGia: 'Tác giả B',
    moTa: 'Sách về Clean Architecture.',
    anhBiaUrl: 'url_b',
    trangThai: 'Het',
    theLoai: 'Công nghệ',
  ),
  BookModel(
    id: 'b3',
    tenSach: 'Kỹ năng mềm',
    tacGia: 'Tác giả C',
    moTa: 'Sách về phát triển cá nhân.',
    anhBiaUrl: 'url_c',
    trangThai: 'Con',
    theLoai: 'Kỹ năng',
  ),
];

// --- Dữ liệu mượn sách ---
List<LoanModel> mockLoans = [
  // Sách b2 đang được u1 mượn và chưa trả
  LoanModel(
    id: 'l1',
    userId: 'u1',
    bookId: 'b2',
    ngayMuon: DateTime(2025, 11, 15),
    ngayTra: null,
  ),
  // Sách b1 đã được u1 mượn và trả
  LoanModel(
    id: 'l2',
    userId: 'u1',
    bookId: 'b1',
    ngayMuon: DateTime(2025, 10, 1),
    ngayTra: DateTime(2025, 10, 8),
  ),
];
