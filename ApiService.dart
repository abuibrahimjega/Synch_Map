// ApiService.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Base URLs - adjust based on environment
  static String get baseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:5000' // Android emulator
      : 'http://192.168.1.14:5000'; // Physical device or iOS simulator

  // Remove text from image
  static Future<File?> removeTextFromImage(File image) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/remove-text'));

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: basename(image.path),
      ));

      request.fields['languages'] = 'en,ar';
      request.fields['inpaint_radius'] = '3';

      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final processedImagePath =
            '${dir.path}/processed_${basename(image.path)}';

        final processedImage = File(processedImagePath);
        await streamedResponse.stream.pipe(processedImage.openWrite());

        return processedImage;
      }
      return null;
    } catch (e) {
      print('Text removal error: $e');
      return null;
    }
  }

  // Upload an image
  static Future<String?> uploadImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: basename(image.path),
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // Text to speech
  static Future<File?> textToSpeech(String text,
      {String engine = 'gtts',
      String language = 'en',
      bool slow = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/speak'),
        body: {
          'text': text,
          'engine': engine,
          'language': language,
          'slow': slow.toString(),
        },
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final audioFile = File(
            '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(response.bodyBytes);
        return audioFile;
      }
      return null;
    } catch (e) {
      print('Text-to-speech error: $e');
      return null;
    }
  }
}
