import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImgBBService {
  final String apiKey = '3bc24b7ca7c261c40a79f93aa1efd21d'; // Thay API Key của bạn vào đây

  Future<String?> uploadImage(File imageFile) async {
    try {
      // API endpoint của ImgBB
      var uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
      
      var request = http.MultipartRequest("POST", uri);
      
      // Thêm file ảnh vào request
      var file = await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(file);

      // Gửi request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var json = jsonDecode(responseData.body);
        // Trả về đường dẫn ảnh trực tiếp (display_url hoặc url)
        return json['data']['url'];
      } else {
        print("Lỗi upload: ${responseData.body}");
        return null;
      }
    } catch (e) {
      print("Lỗi kết nối ImgBB: $e");
      return null;
    }
  }
}