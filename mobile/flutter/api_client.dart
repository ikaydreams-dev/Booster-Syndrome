import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = 'https://api.boostersyndrome.com/api/v1';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<void> delete(String endpoint) async {
    await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
    );
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class User {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
    };
  }
}

class AuthService {
  final ApiClient _client = ApiClient();

  Future<LoginResponse> login(String email, String password) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });

    return LoginResponse.fromJson(response);
  }

  Future<LoginResponse> register(String email, String username, String password) async {
    final response = await _client.post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });

    return LoginResponse.fromJson(response);
  }

  Future<void> logout() async {
    await _client.post('/auth/logout', {});
  }
}

class LoginResponse {
  final User user;
  final String token;
  final String refreshToken;

  LoginResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
      refreshToken: json['refreshToken'],
    );
  }
}
