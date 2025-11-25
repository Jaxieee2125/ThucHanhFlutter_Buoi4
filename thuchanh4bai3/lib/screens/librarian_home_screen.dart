// lib/screens/librarian_home_screen.dart
import 'package:bai3/models/user_model.dart' show UserModel;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../models/book_model.dart';
import '../data/mock_data.dart';
import '../models/user_model.dart';

class LibrarianHomeScreen extends StatefulWidget {
  const LibrarianHomeScreen({super.key});

  @override
  State<LibrarianHomeScreen> createState() => _LibrarianHomeScreenState();
}

class _LibrarianHomeScreenState extends State<LibrarianHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firebaseUser = authProvider.currentFirebaseUser!;
    final userName = firebaseUser.email?.split('@').first ?? 'Thủ thư';

    final List<Widget> _widgetOptions = <Widget>[
      _BookManagementScreen(),
      _LoanTrackingScreen(),
      _StatisticsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Chào mừng, $userName (Thủ thư)'),
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
            icon: Icon(Icons.library_books),
            label: 'Quản lí sách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Theo dõi mượn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
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

// --- Widget 1: Quản lí Sách ---
class _BookManagementScreen extends StatelessWidget {
  void _addBook(BuildContext context, BookProvider bookProvider) {
    final newBook = BookModel(
      id: 'b${bookProvider.books.length + 1}',
      tenSach: 'Sách mới ${bookProvider.books.length + 1}',
      tacGia: 'Thủ thư',
      moTa: 'Sách thêm bởi thủ thư demo.',
      anhBiaUrl: 'url_d',
      trangThai: 'Con',
      theLoai: 'Khác',
    );
    bookProvider.addBook(newBook);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm sách mới thành công!')),
    );
  }

  void _deleteBook(BuildContext context, BookModel book) {
    // Giả lập chức năng xóa (Vì danh sách sách là List<BookModel> final, không thể xóa trực tiếp)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Giả lập xóa sách ${book.tenSach}')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _addBook(context, bookProvider),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Sách Mới'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bookProvider.books.length,
                itemBuilder: (context, index) {
                  final book = bookProvider.books[index];
                  return Card(
                    child: ListTile(
                      title: Text(book.tenSach),
                      subtitle: Text(
                        'ID: ${book.id} - Trạng thái: ${book.trangThai}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Giả lập chức năng Sửa'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBook(context, book),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Widget 2: Theo dõi Mượn ---
class _LoanTrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // Lấy danh sách các khoản mượn chưa trả
        final activeLoans = bookProvider.loans
            .where((l) => l.ngayTra == null)
            .toList();

        return ListView.builder(
          itemCount: activeLoans.length,
          itemBuilder: (context, index) {
            final loan = activeLoans[index];
            final book = bookProvider.books.firstWhere(
              (b) => b.id == loan.bookId,
            );
            // Lấy tên người mượn từ mockUsers (giả lập)
            final user = mockUsers.firstWhere(
              (u) => u.id == loan.userId,
              orElse: () => UserModel(
                id: loan.userId,
                ten: 'Người dùng [Firebase]',
                email: '',
                vaiTro: '',
              ),
            );

            return Card(
              color: Colors.pink[50],
              child: ListTile(
                title: Text('Sách: ${book.tenSach}'),
                subtitle: Text(
                  'Người mượn: ${user.ten} - Ngày mượn: ${loan.ngayMuon.toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.timer, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Widget 3: Đồ thị Thống kê (Giả lập) ---
class _StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Thống kê số lượt mượn theo thời gian\n(Giả lập tính năng nâng cao)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}
