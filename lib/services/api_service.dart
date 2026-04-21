import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.dev.kpi-drive.ru';
  String? _token;

  Future<String> login() async {
    final url = Uri.parse('$baseUrl/api/v2/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': 'кандидат',
        'secret': '123123',
      }),
    );

    print('Login status: ${response.statusCode}');
    print('Login body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Parsed data: $data');
      
      // Исправлено: access_token лежит в data['data']['access_token']
      if (data.containsKey('data') && data['data'] != null) {
        final Map<String, dynamic> innerData = data['data'];
        _token = innerData['access_token'];
      }
      
      if (_token == null) {
        throw Exception('Токен не найден в ответе: ${response.body}');
      }
      return _token!;
    } else {
      throw Exception('Ошибка авторизации: ${response.statusCode}, тело: ${response.body}');
    }
  }

  Future<dynamic> getIndicators() async {
    if (_token == null) await login();

    final url = Uri.parse('$baseUrl/_api/indicators/get_mo_indicators');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['period_start'] = '2026-04-01'
      ..fields['period_end'] = '2026-04-30'
      ..fields['period_key'] = 'month'
      ..fields['requested_mo_id'] = '551';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Indicators status: ${response.statusCode}');
    print('Indicators body: $responseBody');

    if (response.statusCode == 200) {
      if (responseBody.isEmpty) {
        throw Exception('Получен пустой ответ от сервера');
      }
      final decoded = jsonDecode(responseBody);
      if (decoded == null) {
        throw Exception('Ответ сервера null');
      }
      return decoded;
    } else {
      throw Exception('Ошибка получения показателей: ${response.statusCode}, тело: $responseBody');
    }
  }

  Future<Map<String, dynamic>> getIndicatorsWithWrongToken() async {
    final url = Uri.parse('$baseUrl/_api/indicators/get_mo_indicators');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer wrong_token_example'
      ..fields['period_start'] = '2026-04-01'
      ..fields['period_end'] = '2026-04-30'
      ..fields['period_key'] = 'month'
      ..fields['requested_mo_id'] = '551';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Wrong token status: ${response.statusCode}');
    print('Wrong token body: $responseBody');

    return {
      'statusCode': response.statusCode,
      'body': responseBody,
    };
  }

  Future<int?> findPaymentIndicatorId() async {
    final data = await getIndicators();
    
    print('Full response data: $data');
    
    if (data == null) {
      print('Data is null');
      return null;
    }
    
    List indicators = [];
    
    if (data is Map) {
      if (data.containsKey('data') && data['data'] != null) {
        final dataField = data['data'];
        if (dataField is List) {
          indicators = dataField;
        } else if (dataField is Map && dataField.containsKey('items')) {
          indicators = dataField['items'] ?? [];
        } else if (dataField is Map && dataField.containsKey('data')) {
          indicators = dataField['data'] ?? [];
        }
      } else if (data.containsKey('items') && data['items'] != null) {
        indicators = data['items'] as List;
      }
    } else if (data is List) {
      indicators = data;
    }
    
    print('Found ${indicators.length} indicators');
    
    for (var item in indicators) {
      final name = item['name'] ?? item['title'] ?? item['indicator_name'];
      print('Indicator: $name -> ID: ${item['indicator_to_mo_id']}');
      if (name == 'Оплата') {
        return item['indicator_to_mo_id'];
      }
    }
    
    print('Payment indicator not found');
    return null;
  }
}
