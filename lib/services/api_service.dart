import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService{
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static final storage = FlutterSecureStorage();

  static Future<Map<String, String>> _authHeaders() async{
    final accessToken = await(storage.read(key: "access"));
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
}

  static Future<bool> register(String email, String username, String name, String password,) async{
    final response = await http.post(
      Uri.parse("${baseUrl}/auth/register/"),
         headers: {"Content-Type" : "application/json"},
      body: jsonEncode(
        {
          'email': email,
          'username': username,
          'name': name,
          'password': password,
          'password2': password,
        }
      )
    );
    return  response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> login(String email, String password) async{
    final response = await http.post(
      Uri.parse("${baseUrl}/auth/login/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        {
          'email': email,
          'password':password,
        }
      )
    );

    if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        await storage.write(key: 'access', value: data['access']);
        await storage.write(key: 'refresh', value: data['refresh']);
        await storage.write(key: 'user_id', value: data['user_id'].toString());
        return true;
    }
    else{
      print(response.body);
      return false;
    }
  }

  static Future<List> getGroups() async{
    final response = await http.get(
      Uri.parse("${baseUrl}/groups/"),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200 ){
      return jsonDecode(response.body);
    }
    else throw Exception(
      "Error loading groups"
    );
  }

  static Future<bool> createGroup(String name, String currency) async{
      final response = await http.post(
        Uri.parse("${baseUrl}/groups/"),
        headers: await _authHeaders(),
        body: jsonEncode(
            {
              'name' : name,
              'currency' : currency,
        }),
      );
      return response.statusCode == 201;
  }

  static Future<String?> inviteToGroup(int groupId, String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/groups/$groupId/invite"),
      headers: await _authHeaders(),
      body: jsonEncode({
        "email": email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return null;
    } else {
      return data["detail"] ?? "Something went wrong";
    }
  }

  static Future<int?> getCurrentUserId() async {
    final id = await storage.read(key: 'user_id');
    return id != null ? int.parse(id) : null;
  }

  static Future<List> getGroupExpenses(int groupId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/groups/$groupId/expenses/"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load expenses");
    }
  }


  static Future<String?> addExpense({
    required int groupId,
    required String amount,
    required String description,
    required String splitType,
    List<Map<String, dynamic>>? splits,
  }) async {
    final body = {
      "group": groupId,
      "amount": amount,
      "description": description,
      "split_type": splitType,
    };
    
    if (splits != null && splits.isNotEmpty) {
      body["splits"] = splits;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/expenses/"),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return null;
    } else {
      final data = jsonDecode(response.body);
      return data["detail"] ?? "Failed to add expense";
    }
  }

  static Future<Map<String, dynamic>> getGroupDetail(int groupId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/groups/$groupId/detail/"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load group detail: ${response.statusCode} - ${response.body}");
    }
  }



}
