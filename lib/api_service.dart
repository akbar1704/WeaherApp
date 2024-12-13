import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.90.33.137:3000/users';

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<bool> login(String username, String password) async {
    final users = await fetchUsers();
    for (var user in users) {
      if (user['username'] == username && user['password'] == password) {
        return true;
      }
    }
    return false;
  }

  Future<bool> register(
      String username, String password, String email, String fullName) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
        'full_name': fullName,
      }),
    );
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>> getUserDetails(String username) async {
    final users = await fetchUsers();
    for (var user in users) {
      if (user['username'] == username) {
        return user;
      }
    }
    throw Exception('User not found');
  }

  Future<bool> updateUserDetails(
      String id, Map<String, dynamic> userDetails) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userDetails),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return response.statusCode == 200;
  }
}
