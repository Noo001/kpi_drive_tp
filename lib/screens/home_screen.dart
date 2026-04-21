import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  String _token = '';
  String _indicatorsResult = '';
  String _paymentIdResult = '';
  String _errorResult = '';

  bool _isLoading = false;

  void _showExplanation(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _step1Login() async {
    setState(() => _isLoading = true);
    try {
      final token = await _api.login();
      setState(() {
        _token = token;
        _indicatorsResult = '';
        _paymentIdResult = '';
      });
      _showExplanation(
        '✅ Шаг 1: Токен получен',
        'Токен: $token\n\nИспользуйте его в заголовке Authorization: Bearer <token>',
      );
    } catch (e) {
      _showExplanation('❌ Ошибка', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _step2GetIndicators() async {
    if (_token.isEmpty) {
      _showExplanation('⚠️ Внимание', 'Сначала получите токен (Шаг 1)');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await _api.getIndicators();
      setState(() {
        _indicatorsResult = data.toString();
      });
      int count = 0;
      if (data is List) {
        count = data.length;
      } else if (data is Map && data['data'] is List) {
        count = (data['data'] as List).length;
      }
      _showExplanation(
        '📊 Шаг 2: Список показателей',
        'Ответ получен. Всего элементов: $count\n\nСмотрите результат в поле вывода ниже.',
      );
    } catch (e) {
      _showExplanation('❌ Ошибка', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _step3FindPayment() async {
    if (_token.isEmpty) {
      _showExplanation('⚠️ Внимание', 'Сначала получите токен');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final id = await _api.findPaymentIndicatorId();
      setState(() {
        _paymentIdResult = id != null ? id.toString() : 'Не найден';
      });
      _showExplanation(
        '💰 Шаг 3: Показатель "Оплата"',
        id != null
            ? 'indicator_to_mo_id = $id\n\nОтправьте этот ID в ответе на задание.'
            : 'Показатель "Оплата" не найден в ответе.',
      );
    } catch (e) {
      _showExplanation('❌ Ошибка', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _step4WrongToken() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getIndicatorsWithWrongToken();
      setState(() {
        _errorResult = 'Статус: ${result['statusCode']}\nТело: ${result['body']}';
      });
      _showExplanation(
        '🔐 Шаг 4: Неверный токен',
        'Ожидаемый HTTP-статус: 401 Unauthorized\nТело ошибки: {"message": "Unauthorized"} или подобное\n\nФактический ответ:\n${result['statusCode']}\n${result['body']}',
      );
    } catch (e) {
      _showExplanation('❌ Ошибка', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KPI Drive ТП тест')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 Пошаговые действия',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildButton('1. Получить токен', _step1Login, Colors.blue),
                _buildButton('2. Список показателей', _step2GetIndicators, Colors.green),
                _buildButton('3. Найти "Оплата"', _step3FindPayment, Colors.orange),
                _buildButton('4. Неверный токен (тест ошибки)', _step4WrongToken, Colors.red),
              ],
            ),
            SizedBox(height: 24),
            if (_token.isNotEmpty) ...[
              Text('🔑 Токен:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_token, style: TextStyle(fontSize: 12)),
              SizedBox(height: 12),
            ],
            if (_indicatorsResult.isNotEmpty) ...[
              Text('📦 Ответ показателей:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.grey[200],
                child: SelectableText(_indicatorsResult, style: TextStyle(fontSize: 12)),
              ),
              SizedBox(height: 12),
            ],
            if (_paymentIdResult.isNotEmpty) ...[
              Text('💰 indicator_to_mo_id для "Оплата":', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_paymentIdResult, style: TextStyle(fontSize: 16, color: Colors.green)),
              SizedBox(height: 12),
            ],
            if (_errorResult.isNotEmpty) ...[
              Text('⚠️ Тест с неверным токеном:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.all(8),
                color: Colors.red[50],
                child: SelectableText(_errorResult, style: TextStyle(fontSize: 12)),
              ),
            ],
            if (_isLoading) Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }
}
