import 'package:http/http.dart' as http;

class DBConnection {
  static const String baseUrl = 'http://192.168.1.14:5000';
  static Future<bool> isUserAdmin(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.14:5000/user/$userId/isadmin'),
      );
      return response.statusCode == 200 &&
          response.body.toLowerCase() == 'true';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  static Future<bool> addFloor(
      int mapId, String floorName, String imagePath) async {
    try {
      // Add your database logic here to insert a new floor
      // This is a placeholder implementation
      return true;
    } catch (e) {
      print('Error adding floor: $e');
      return false;
    }
  }

  static Future<bool> isUserMapOwner(int userId, int mapId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/maps/owner/$userId/$mapId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking map ownership: $e');
      return false;
    }
  }

  static getPOIData(int parsedPoiId) {}

  static Future<bool> editFloorInfo(
      {required int floorId,
      required int mapId,
      String? newFloorName,
      String? newImagePath}) async {
    try {
      // Add your database logic here to update the floor information
      // This is a placeholder implementation
      return true;
    } catch (e) {
      print('Error editing floor info: $e');
      return false;
    }
  }
}
