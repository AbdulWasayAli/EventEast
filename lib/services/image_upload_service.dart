import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


/// fails with `object-not-found`
class ImageUploadService {
  ImageUploadService._();

  static const String _cloudName = 'don1e4hj5';
  static const String _uploadPreset = 'flutter_upload';

  /// Uploads [file] and returns its `secure_url`.
  ///
  /// Throws an [Exception] carrying a message that is safe to show the user.
  static Future<String> uploadImage(File file) async {
    if (!await file.exists() || await file.length() == 0) {
      throw Exception('Selected image file not found.');
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.StreamedResponse response = await request.send();
    final String body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(_readError(body));
    }

    final Map<String, dynamic> data =
        jsonDecode(body) as Map<String, dynamic>;
    final Object? url = data['secure_url'];

    if (url is! String || url.isEmpty) {
      throw Exception('Upload succeeded but no image URL was returned.');
    }

    return url;
  }

  static String _readError(String body) {
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(body) as Map<String, dynamic>;
      final Object? error = decoded['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    } catch (_) {
    }
    return 'Could not upload image. Please try again.';
  }
}
