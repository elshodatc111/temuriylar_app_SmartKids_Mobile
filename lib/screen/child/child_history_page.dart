import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ChildHistoryPage extends StatefulWidget {
  final int id;

  const ChildHistoryPage({super.key, required this.id});

  @override
  State<ChildHistoryPage> createState() => _ChildHistoryPageState();
}

class _ChildHistoryPageState extends State<ChildHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();

  List historyList = [];
  List paymentsList = [];
  bool isLoading = true;
  late String lang;

  // Lug'at markazlashtirildi
  final Map<String, Map<String, String>> _words = {
    'uz': {
      'history': "Bola tarixi",
      'actions': "Harakatlar",
      'payments': "To'lovlar",
      'no_data': "Ma'lumot topilmadi",
      'cash_pay': "NAQD TO'LOV",
      'card_pay': "KARTA TO'LOVI",
      'bank_pay': "BANK TO'LOVI",
      'group_pay': "GURUH TO'LOVI",
      'group_add': "GURUHGA QO'SHILDI",
      'group_delete': "GURUHDAN O'CHIRILDI",
      'discount_add': "CHEGIRMA",
      'return_cash_pay': "NAQD QAYTARILDI",
      'return_card_pay': "KARTAGA QAYTARILDI",
      'visited': "TASHRIF",
      'action': "HARAKAT",
      'currency': "so'm",
      'kassir': "Kassir",
    },
    'ru': {
      'history': "История ребенка",
      'actions': "Действия",
      'payments': "Платежи",
      'no_data': "Данные не найдены",
      'cash_pay': "НАЛИЧНАЯ ОПЛАТА",
      'card_pay': "ОПЛАТА КАРТОЙ",
      'bank_pay': "БАНКОВСКИЙ ПЕРЕВОД",
      'group_pay': "ОПЛАТА ГРУППЫ",
      'group_add': "ДОБАВЛЕН В ГРУППУ",
      'group_delete': "УДАЛЕН ИЗ ГРУППЫ",
      'discount_add': "СКИДКА",
      'return_cash_pay': "ВОЗВРАТ НАЛИЧНЫМИ",
      'return_card_pay': "ВОЗВРАТ НА КАРТУ",
      'visited': "ВИЗИТ",
      'action': "ДЕЙСТВИЕ",
      'currency': "сум",
      'kassir': "Кассир",
    },
  };

  @override
  void initState() {
    super.initState();
    lang = box.read('lang') ?? 'uz';
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting(lang, null).then((_) => _fetchAllData());
  }

  String t(String key) => _words[lang]![key] ?? key;

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);
    String? token = box.read('token');
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConst.apiUrl}/kids/histore/${widget.id}'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${ApiConst.apiUrl}/kids/paymart/${widget.id}'),
          headers: headers,
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          historyList = json.decode(responses[0].body)['kid'] ?? [];
          paymentsList = json.decode(responses[1].body)['payment'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Xatolik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('history'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigoAccent,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.indigoAccent,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              child: Text(
                t('actions'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Tab(
              child: Text(
                t('payments'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: SpinKitThreeBounce(color: Colors.indigoAccent, size: 35.0),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildHistoryTab(), _buildPaymentsTab()],
            ),
    );
  }

  Widget _buildHistoryTab() {
    if (historyList.isEmpty) return _emptyState();
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final item = historyList[index];
          return _historyCard(item);
        },
      ),
    );
  }

  Widget _historyCard(Map item) {
    String type = item['type'] ?? '';
    Color mainColor = _getHistoryColor(type);
    IconData icon = _getHistoryIcon(type);
    String typeLabel = _getTypeLabel(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: mainColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ),
                      if (item['amount'] != null)
                        Text(
                          "${item['amount']} ${t('currency')}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['description'] ?? '---',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['user']['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(item['created_at']),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (paymentsList.isEmpty) return _emptyState();
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paymentsList.length,
        itemBuilder: (context, index) {
          final item = paymentsList[index];
          return _paymentCard(item);
        },
      ),
    );
  }

  Widget _paymentCard(Map item) {
    String status = item['status'] ?? '';
    Color statusColor = status == 'success'
        ? Colors.green
        : (status == 'cancel' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item['amount']} ${t('currency')}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    item['payment_type'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade300,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.history_edu, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${t('kassir')}: ${item['kassir'] ?? ''}",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              Text(
                _formatDate(item['created_at']),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd.MM.yyyy | HH:mm', lang).format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'cash_pay':
        return t('cash_pay');
      case 'card_pay':
        return t('card_pay');
      case 'bank_pay':
        return t('bank_pay');
      case 'group_pay':
        return t('group_pay');
      case 'group_add':
        return t('group_add');
      case 'group_delte':
        return t(
          'group_delete',
        ); // API dagi xato saqlandi lekin label tuzatildi
      case 'discount_add':
        return t('discount_add');
      case 'return_cash_pay':
        return t('return_cash_pay');
      case 'return_card_pay':
        return t('return_card_pay');
      case 'vizited':
        return t('visited');
      default:
        return t('action');
    }
  }

  Color _getHistoryColor(String type) {
    switch (type) {
      case 'cash_pay':
      case 'card_pay':
      case 'bank_pay':
      case 'group_pay':
        return Colors.green;
      case 'group_add':
        return Colors.blue;
      case 'group_delte':
        return Colors.red;
      case 'discount_add':
        return Colors.orange;
      case 'return_cash_pay':
      case 'return_card_pay':
        return Colors.purple;
      case 'vizited':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getHistoryIcon(String type) {
    switch (type) {
      case 'cash_pay':
      case 'card_pay':
      case 'bank_pay':
      case 'group_pay':
        return Icons.account_balance_wallet_rounded;
      case 'group_add':
        return Icons.group_add_rounded;
      case 'group_delte':
        return Icons.group_remove_rounded;
      case 'discount_add':
        return Icons.loyalty_rounded;
      case 'return_cash_pay':
      case 'return_card_pay':
        return Icons.assignment_return_rounded;
      case 'vizited':
        return Icons.sensor_door_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Widget _emptyState() {
    return Center(
      child: Text(t('no_data'), style: TextStyle(color: Colors.grey.shade400)),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
