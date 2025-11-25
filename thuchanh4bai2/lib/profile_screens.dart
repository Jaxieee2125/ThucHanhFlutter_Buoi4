import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'imgbb_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  bool _isUploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Lấy ảnh hiện tại từ Firestore
  void _loadUserProfile() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data()!.containsKey('avatarUrl')) {
        setState(() {
          _avatarUrl = doc['avatarUrl'];
        });
      }
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _uploadToImgBB();
    }
  }

  // Upload và cập nhật Firestore
  Future<void> _uploadToImgBB() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    // 1. Upload lên ImgBB
    String? url = await ImgBBService().uploadImage(_imageFile!);

    if (url != null) {
      // 2. Lưu URL vào Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'avatarUrl': url,
          'email': user!.email, 
        }, SetOptions(merge: true));
      }

      setState(() {
        _avatarUrl = url;
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")),
      );
    } else {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi upload ảnh!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              // Hiển thị Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider
                    : (_avatarUrl != null
                        ? CachedNetworkImageProvider(_avatarUrl!)
                        : null),
                child: (_imageFile == null && _avatarUrl == null)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
              // Nút icon máy ảnh
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    onPressed: _isUploading ? null : _pickImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(user?.email ?? "User", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          if (_isUploading) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}