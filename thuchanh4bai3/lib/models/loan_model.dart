class LoanModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime ngayMuon;
  DateTime? ngayTra; // Null nếu sách chưa trả

  LoanModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.ngayMuon,
    this.ngayTra,
  });
}
