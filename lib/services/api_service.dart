import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService{
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static final storage = FlutterSecureStorage();

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
        return true;
    }
    else{
      print(response.body);
      return false;
    }
  }
}
