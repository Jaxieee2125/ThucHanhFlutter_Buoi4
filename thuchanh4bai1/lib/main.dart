// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thuchanh4bai1/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// ==========================================
// BƯỚC 1: CẤU TRÚC CƠ BẢN & MODEL
// ==========================================

// Model sản phẩm (Product)
class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String image;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.image,
  });

  // Hàm factory để chuyển đổi JSON từ API thành đối tượng Product (Bước 6)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      // API FakeStore đôi khi trả về int hoặc double
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      image: json['image'],
    );
  }
}

// ==========================================
// BƯỚC 5 & 6: QUẢN LÝ TRẠNG THÁI & API SERVICE
// ==========================================

// Service để gọi API (Bước 6)
class ProductService {
  static const String apiUrl = 'https://fakestoreapi.com/products';

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Không thể tải danh sách sản phẩm');
    }
  }
}

// Provider quản lý giỏ hàng (Bước 5)
class CartProvider with ChangeNotifier {
  // Map để lưu sản phẩm và số lượng: key là id sản phẩm
  final Map<int, CartItemModel> _items = {};

  Map<int, CartItemModel> get items => _items;

  // Lấy tổng số tiền
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Thêm vào giỏ hàng
  void addToCart(Product product) {
    if (_items.containsKey(product.id)) {
      // Nếu đã có thì tăng số lượng
      _items.update(
        product.id,
        (existingCartItem) => CartItemModel(
          id: existingCartItem.id,
          title: existingCartItem.title,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          image: existingCartItem.image,
        ),
      );
    } else {
      // Chưa có thì thêm mới
      _items.putIfAbsent(
        product.id,
        () => CartItemModel(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: 1,
          image: product.image,
        ),
      );
    }
    notifyListeners(); // Cập nhật UI
  }

  // Giảm số lượng hoặc xóa
  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItemModel(
          id: existingCartItem.id,
          title: existingCartItem.title,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
          image: existingCartItem.image,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }
  
  // Xóa hẳn sản phẩm khỏi giỏ
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Xóa giỏ hàng
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// Model phụ cho item trong giỏ hàng (có thêm số lượng)
class CartItemModel {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final String image;

  CartItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

// ==========================================
// MAIN APP
// ==========================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo Firebase
  // Bọc toàn bộ ứng dụng bằng ChangeNotifierProvider (Bước 5)
  runApp(
    ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Online Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), // Lắng nghe trạng thái đăng nhập
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Đã đăng nhập -> Vào màn hình danh sách sản phẩm
            return const ProductListScreen();
          }
          // Chưa đăng nhập -> Vào màn hình Login
          return const LoginScreen();
        },
      ),
    );
  }
}

// ==========================================
// BƯỚC 2: MÀN HÌNH DANH SÁCH SẢN PHẨM
// ==========================================

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API khi màn hình khởi tạo (Bước 6 - FutureBuilder chuẩn bị)
    _productsFuture = ProductService().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng Online'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Chuyển sang màn hình giỏ hàng
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      // Sử dụng FutureBuilder để xử lý trạng thái tải dữ liệu (Bước 6)
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sản phẩm nào.'));
          } else {
            // Hiển thị GridView (Bước 2)
            return GridView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, i) => ProductCard(product: snapshot.data![i]),
            );
          }
        },
      ),
    );
  }
}

// Widget ProductCard riêng biệt (Bước 2)
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Hiệu ứng nhấn bằng GestureDetector/InkWell
    return GestureDetector(
      onTap: () {
        // Chuyển đến màn hình chi tiết (Bước 3)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  product.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ),
            // Thêm nút nhanh để test add to cart (Optional UI enhancement)
            Container(
              width: double.infinity,
              // ignore: deprecated_member_use
              color: Colors.blueAccent.withOpacity(0.1),
              child: IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã thêm vào giỏ!"), duration: Duration(seconds: 1)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BƯỚC 3: MÀN HÌNH CHI TIẾT SẢN PHẨM
// ==========================================

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.network(product.image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              '\$${product.price}',
              style: const TextStyle(color: Colors.grey, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                product.description,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
      // Nút thêm vào giỏ hàng ở dưới cùng
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () {
            // Gọi hàm addToCart từ Provider (Bước 5)
            Provider.of<CartProvider>(context, listen: false).addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Đã thêm vào giỏ hàng!")),
            );
          },
          child: const Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

// ==========================================
// BƯỚC 4: MÀN HÌNH GIỎ HÀNG
// ==========================================

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ CartProvider
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: Column(
        children: [
          // Phần tóm tắt đơn hàng (Bước 4)
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
  onPressed: () async {
    if (cart.items.isEmpty) return;

    // 1. Lấy user hiện tại
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
        // Xử lý trường hợp chưa đăng nhập (lý thuyết không xảy ra do đã chặn ở main)
        return;
    }

    // 2. Hiển thị loading (đơn giản)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đang xử lý đơn hàng...")),
    );

    try {
      // 3. Gửi dữ liệu lên Firestore (Collection 'orders')
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'email': user.email,
        'amount': cart.totalAmount,
        'dateTime': DateTime.now().toIso8601String(),
        'products': cart.items.values.map((cp) => {
           'id': cp.id,
           'title': cp.title,
           'quantity': cp.quantity,
           'price': cp.price,
        }).toList(),
      });

      // 4. Xóa giỏ hàng
      cart.clearCart();

      // 5. Chuyển đến màn hình thành công (hoặc thông báo)
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => const OrderSuccessScreen(),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  },
  child: const Text('THANH TOÁN'),
)
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Danh sách sản phẩm trong giỏ hàng (Bước 4 - ListView.builder)
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) => CartItemWidget(
                cartItem: cartItems[i],
                productId: cart.items.keys.toList()[i],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thành công")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Đặt hàng thành công!", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Quay về màn hình chính (xóa hết các màn hình trước đó trong stack)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Tiếp tục mua sắm"),
            )
          ],
        ),
      ),
    );
  }
}

// Widget riêng cho từng mục trong giỏ hàng
class CartItemWidget extends StatelessWidget {
  final CartItemModel cartItem;
  final int productId;

  const CartItemWidget({
    super.key, 
    required this.cartItem, 
    required this.productId
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cartItem.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<CartProvider>(context, listen: false).removeItem(productId);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: const Icon(Icons.delete, color: Colors.white, size: 40),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(cartItem.image),
              backgroundColor: Colors.transparent,
            ),
            title: Text(cartItem.title),
            subtitle: Text('Tổng: \$${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                     Provider.of<CartProvider>(context, listen: false).removeSingleItem(productId);
                  },
                ),
                Text('${cartItem.quantity} x'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                     // Tạo đối tượng Product tạm để tái sử dụng hàm addToCart
                     final tempProduct = Product(
                       id: productId, 
                       title: cartItem.title, 
                       price: cartItem.price, 
                       description: '', 
                       image: cartItem.image
                     );
                     Provider.of<CartProvider>(context, listen: false).addToCart(tempProduct);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}