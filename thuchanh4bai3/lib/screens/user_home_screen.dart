// lib/screens/user_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../models/book_model.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firebaseUser = authProvider.currentFirebaseUser!;

    // Sử dụng UID và Email từ Firebase
    final userId = firebaseUser.uid;
    final userName = firebaseUser.email?.split('@').first ?? 'Người dùng';

    final List<Widget> _widgetOptions = <Widget>[
      _BookCatalogScreen(currentUserId: userId), // Truyền UID Firebase
      _UserLoanHistory(userId: userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Chào mừng, $userName (Người dùng)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Danh mục sách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch sử mượn',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// --- Widget 1: Danh mục Sách ---
class _BookCatalogScreen extends StatelessWidget {
  final String currentUserId;
  const _BookCatalogScreen({required this.currentUserId});

  void _borrowBook(BuildContext context, BookModel book) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);

    try {
      // Dùng currentUserId (Firebase UID)
      bookProvider.borrowBook(currentUserId, book.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã mượn sách "${book.tenSach}" thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString().split(':').last}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        return ListView.builder(
          itemCount: bookProvider.books.length,
          itemBuilder: (context, index) {
            final book = bookProvider.books[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.book),
                title: Text(book.tenSach),
                subtitle: Text(
                  '${book.tacGia} - Trạng thái: ${book.trangThai}',
                ),
                trailing: book.trangThai == 'Con'
                    ? ElevatedButton(
                        onPressed: () => _borrowBook(context, book),
                        child: const Text('Mượn'),
                      )
                    : const Text('Hết', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chi tiết sách: ${book.moTa}')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- Widget 2: Lịch sử Mượn ---
class _UserLoanHistory extends StatelessWidget {
  final String userId;
  const _UserLoanHistory({required this.userId});

  void _returnBook(BuildContext context, loan) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.returnBook(loan);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã trả sách thành công!')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        final userLoans = bookProvider.getUserLoans(userId);

        // Cần giả lập tên sách cho mỗi LoanModel
        BookModel getBook(String bookId) =>
            bookProvider.books.firstWhere((b) => b.id == bookId);

        return ListView.builder(
          itemCount: userLoans.length,
          itemBuilder: (context, index) {
            final loan = userLoans[index];
            final book = getBook(loan.bookId);
            final isReturned = loan.ngayTra != null;

            return Card(
              color: isReturned ? Colors.grey[200] : Colors.amber[100],
              child: ListTile(
                title: Text('Sách: ${book.tenSach}'),
                subtitle: Text(
                  'Mượn: ${loan.ngayMuon.toString().split(' ')[0]} - Trả: ${isReturned ? loan.ngayTra!.toString().split(' ')[0] : 'Chưa trả'}',
                ),
                trailing: !isReturned
                    ? ElevatedButton(
                        onPressed: () => _returnBook(context, loan),
                        child: const Text('Trả sách'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}
