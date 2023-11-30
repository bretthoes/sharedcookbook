import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<List<dynamic>> getCookbooks() async {
    final response = await http
        .get(Uri.parse('${dotenv.env['API_URL']}Cookbooks/person/1/cookbooks'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cookbooks');
    }
  }
}
