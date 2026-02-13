import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class KassaPendingPayment extends StatefulWidget {
  const KassaPendingPayment({super.key});

  @override
  State<KassaPendingPayment> createState() => _KassaPendingPaymentState();
}

class _KassaPendingPaymentState extends State<KassaPendingPayment> {
  final box = GetStorage();
  late String lang;
  late String token;
  late String userType;

  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    lang = box.read('lang') ?? 'uz';
    token = box.read('token') ?? '';
    // Profile ichidagi user type ni aniqlash
    userType = box.read('profile')?['type'] ?? 'user';
  }

  final Map<String, Map<String, String>> _words = {
    'title': {'uz': "Tasdiqlanmagan to'lovlar", 'ru': "Неподтвержденные платежи"},
    'card': {'uz': "Karta orqali", 'ru': "Через карту"},
    'bank': {'uz': "Bank orqali", 'ru': "Через банк"},
    'discount': {'uz': "Chegirma", 'ru': "Скидка"},
    'empty': {'uz': "Tasdiqlanmagan to'lovlar mavjud emas", 'ru': "Нет неподтвержденных платежей"},
    'manager': {'uz': "Menejer", 'ru': "Менеджер"},
    'cancel': {'uz': "Bekor qilish", 'ru': "Отменить"},
    'confirm': {'uz': "Tasdiqlash", 'ru': "Подтвердить"},
    'currency': {'uz': "UZS", 'ru': "UZS"},
    'description': {'uz': "Izoh", 'ru': "Примечание"},
  };

  String t(String key) => _words[key]?[lang] ?? key;

  String formatMoney(dynamic amount) => NumberFormat.decimalPattern('uz').format(amount);

  Future<Map<String, dynamic>> getPendingPayments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kids/paymarts/pedding'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> processPayment(int id, String action) async {
    final String loadingKey = "${id}_$action";
    setState(() => _loadingStates[loadingKey] = true);

    final String url = action == 'confirm'
        ? '${ApiConst.apiUrl}/kids/paymart/success/$id'
        : '${ApiConst.apiUrl}/kids/paymart/cancel/$id';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {}); // Ro'yxatni yangilash
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Xatolik: $e")));
    } finally {
      if (mounted) setState(() => _loadingStates[loadingKey] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getPendingPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildShimmerEffect();
          if (snapshot.hasError) return Center(child: Text("${snapshot.error}"));

          final summary = snapshot.data!;
          final List<dynamic> listData = summary['data'] ?? [];

          return Column(
            children: [
              _buildHeaderSummary(summary),
              Expanded(
                child: listData.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: listData.length,
                  itemBuilder: (context, index) => _buildPaymentCard(listData[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(dynamic item) {
    final int id = item['id'];
    final String payType = item['payment_type'];
    DateTime date = DateTime.parse(item['created_at']);
    String formattedDate = DateFormat('dd.MM.yyyy | HH:mm').format(date);

    // To'lov turi uchun rang va ikonka sozlamalari
    IconData typeIcon;
    Color typeColor;
    String typeText;

    switch (payType) {
      case 'card':
        typeIcon = Icons.credit_card_rounded;
        typeColor = Colors.blue;
        typeText = t('card');
        break;
      case 'bank':
        typeIcon = Icons.account_balance_rounded;
        typeColor = Colors.green;
        typeText = t('bank');
        break;
      default:
        typeIcon = Icons.loyalty_rounded;
        typeColor = Colors.orange;
        typeText = t('discount');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1-qator: Ism va Summa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item['kids']['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text("${formatMoney(item['amount'])} ${t('currency')}",
                  style: TextStyle(fontWeight: FontWeight.w800, color: typeColor, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),

          // 2-qator: To'lov turi va Kassir
          Row(
            children: [
              Icon(typeIcon, size: 14, color: typeColor),
              const SizedBox(width: 4),
              Text(typeText, style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              const Icon(Icons.person_pin, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text("${item['kassir']}", style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFF1F2F6)),

          // 3-qator: Izoh (Description)
          if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${t('description')}: ", style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(child: Text("${item['description']}", style: TextStyle(color: Colors.grey[700], fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Sana
          Align(
            alignment: Alignment.centerRight,
            child: Text(formattedDate, style: const TextStyle(color: Colors.black26, fontSize: 10)),
          ),

          // Admin tugmalari
          if (userType == 'admin') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(id: id, action: 'cancel', label: t('cancel'), color: Colors.redAccent, icon: Icons.close_rounded),
                const SizedBox(width: 12),
                _buildActionButton(id: id, action: 'confirm', label: t('confirm'), color: Colors.green, icon: Icons.check_rounded),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({required int id, required String action, required String label, required Color color, required IconData icon}) {
    bool isLoading = _loadingStates["${id}_$action"] ?? false;
    return Expanded(
      child: InkWell(
        onTap: isLoading ? null : () => processPayment(id, action),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(
            child: isLoading
                ? SpinKitThreeBounce(color: color, size: 18)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Summary Header ---
  Widget _buildHeaderSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          _buildSummaryItem(t('card').split(' ')[0], summary['card'], Colors.blue),
          _buildSummaryItem(t('bank').split(' ')[0], summary['bank'], Colors.green),
          _buildSummaryItem(t('discount'), summary['discount'], Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, dynamic value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 4),
        Text(formatMoney(value), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        const Text("UZS", style: TextStyle(color: Colors.grey, fontSize: 9)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(t('empty'), style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Column(children: [
      Container(height: 80, color: Colors.white),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: 5,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 160,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ),
    ]);
  }
}