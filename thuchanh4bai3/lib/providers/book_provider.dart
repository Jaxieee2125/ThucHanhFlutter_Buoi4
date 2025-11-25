// lib/providers/book_provider.dart
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/loan_model.dart';
import '../data/mock_data.dart';

class BookProvider with ChangeNotifier {
  // Sử dụng bản sao để có thể sửa đổi trạng thái (trangThai của sách)
  final List<BookModel> _books = [...mockBooks];
  final List<LoanModel> _loans = [...mockLoans];

  List<BookModel> get books => _books;
  List<LoanModel> get loans => _loans;

  // --- Chức năng Người dùng: Mượn sách ---
  void borrowBook(String userId, String bookId) {
    final book = _books.firstWhere((b) => b.id == bookId);

    if (book.trangThai == 'Con') {
      // 1. Cập nhật trạng thái sách
      book.trangThai = 'Het';

      // 2. Tạo bản ghi mượn mới
      final newLoan = LoanModel(
        id: 'l${_loans.length + 1}',
        userId: userId,
        bookId: bookId,
        ngayMuon: DateTime.now(),
      );
      _loans.add(newLoan);

      notifyListeners();
    } else {
      throw Exception('Sách đã hết!');
    }
  }

  // Lấy lịch sử mượn của một người dùng
  List<LoanModel> getUserLoans(String userId) {
    // Lưu ý: Trong demo này, userId là Firebase UID,
    // nhưng bookId và loanId vẫn là id tĩnh (b1, l1).
    return _loans.where((loan) => loan.userId == userId).toList();
  }

  // --- Chức năng Người dùng/Thủ thư: Trả sách ---
  void returnBook(LoanModel loan) {
    // Tìm và cập nhật trạng thái sách
    final book = _books.firstWhere((b) => b.id == loan.bookId);
    book.trangThai = 'Con';

    // Cập nhật bản ghi mượn (đặt ngày trả)
    loan.ngayTra = DateTime.now();

    notifyListeners();
  }

  // --- Chức năng Thủ thư: Quản lý sách ---
  void addBook(BookModel newBook) {
    _books.add(newBook);
    notifyListeners();
  }
}
