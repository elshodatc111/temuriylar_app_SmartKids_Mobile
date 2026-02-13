import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class IshHaqiTulovlari extends StatefulWidget {
  final int id;

  const IshHaqiTulovlari({super.key, required this.id});

  @override
  State<IshHaqiTulovlari> createState() => _IshHaqiTulovlariState();
}

class _IshHaqiTulovlariState extends State<IshHaqiTulovlari> {
  final box = GetStorage();
  bool isLoading = true;
  List payments = [];
  late String lang;
  final f = NumberFormat("#,###", "uz_UZ");

  // Tarjimalar lug'ati
  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': "Ish haqi tarixi",
      'no_data': "To'lovlar topilmadi",
      'amount': "To'lov summasi",
      'type': "Turi",
      'date': "Sana",
      'desc': "Izoh",
      'cash': "Naqd",
      'card': "Karta",
      'bank': "Bank",
    },
    'ru': {
      'title': "История зарплаты",
      'no_data': "Платежи не найдены",
      'amount': "Сумма оплаты",
      'type': "Тип",
      'date': "Дата",
      'desc': "Примечание",
      'cash': "Наличные",
      'card': "Карта",
      'bank': "Банк",
    },
  };

  @override
  void initState() {
    super.initState();
    lang = box.read('lang') ?? 'uz';
    _fetchPayments();
  }

  String t(String key) => _words[lang]![key] ?? key;

  Future<void> _fetchPayments() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    String? token = box.read('token');
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConst.apiUrl}/emploes/show/paymart/${widget.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded['status'] == true) {
          if (mounted) {
            setState(() {
              payments = decoded['paymarts'];
              isLoading = false;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Payment History Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('title'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? _buildShimmerEffect()
          : RefreshIndicator(
              onRefresh: _fetchPayments,
              color: Colors.indigoAccent,
              child: payments.isEmpty
                  ? _buildEmptyState()
                  : _buildPaymentList(),
            ),
    );
  }

  Widget _buildPaymentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final item = payments[index];
        return _buildPaymentCard(item);
      },
    );
  }

  Widget _buildPaymentCard(Map item) {
    String type = item['type'] ?? 'cash';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${f.format(item['amount'])} UZS",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${t('type')}: ${t(type)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDate(item['created_at']),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item['description'] != null &&
              item['description'].toString().isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['description'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat("dd.MM.yyyy").format(dt);
    } catch (e) {
      return dateStr.split(" ")[0];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            t('no_data'),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
