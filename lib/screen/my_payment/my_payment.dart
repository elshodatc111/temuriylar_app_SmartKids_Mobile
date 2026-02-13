import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class MyPayment extends StatefulWidget {
  const MyPayment({super.key});

  @override
  State<MyPayment> createState() => _MyPaymentState();
}

class _MyPaymentState extends State<MyPayment> {
  final GetStorage _storage = GetStorage();
  bool _isLoading = true;
  List<dynamic> _payments = [];
  late String currentLang;

  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': 'Ish haqi tarixi',
      'total': 'Jami tushum',
      'type': 'To\'lov turi',
      'cash': 'Naqd',
      'card': 'Karta',
      'bank': 'Bank o\'tkazmasi',
      'no_data': 'To\'lovlar topilmadi',
      'error': 'Ma’lumot yuklashda xato',
    },
    'ru': {
      'title': 'История зарплаты',
      'total': 'Общий приход',
      'type': 'Тип оплаты',
      'cash': 'Наличные',
      'card': 'Карта',
      'bank': 'Перевод',
      'no_data': 'Платежи не найдены',
      'error': 'Ошибка при загрузке',
    },
  };

  @override
  void initState() {
    super.initState();
    currentLang = _storage.read('lang') ?? 'uz';
    _fetchPayments();
  }

  String _t(String key) => _words[currentLang]?[key] ?? key;

  Future<void> _fetchPayments() async {
    final profile = _storage.read('profile');
    final token = _storage.read('token');

    if (profile == null) return;

    final int id = profile['id'];
    final url = '${ApiConst.apiUrl}/emploes/show/paymart/$id';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _payments = decoded['paymarts'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(_t('error'), e.toString());
    }
  }

  // To'lov turi uchun ikonka va rang
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.orange;
      case 'bank':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t('title'))),
      body: _isLoading
          ? _buildShimmer()
          : Column(
              children: [
                SizedBox(height: 12),
                Expanded(
                  child: _payments.isEmpty
                      ? Center(child: Text(_t('no_data')))
                      : _buildPaymentList(),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final pay = _payments[index];
        final DateTime date = DateTime.parse(pay['created_at']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor(pay['type']).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(pay['type']),
                color: _getTypeColor(pay['type']),
              ),
            ),
            title: Text(
              "${NumberFormat('#,###').format(pay['amount'])} UZS",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _t(pay['type']),
                  style: TextStyle(
                    color: _getTypeColor(pay['type']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pay['description'] != null && pay['description'] != "")
                  Text(
                    pay['description'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Text(
              DateFormat('dd.MM.yyyy\nHH:mm').format(date),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
