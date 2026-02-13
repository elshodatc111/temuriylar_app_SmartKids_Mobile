import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Shimmerni import qilamiz

class KassaReturnPayment extends StatefulWidget {
  const KassaReturnPayment({super.key});

  @override
  State<KassaReturnPayment> createState() => _KassaReturnPaymentState();
}

class _KassaReturnPaymentState extends State<KassaReturnPayment> {
  final lang = GetStorage().read('lang') ?? 'uz';
  final String token = GetStorage().read('token') ?? '';

  final Map<String, Map<String, String>> _words = {
    'title': {'uz': "Qaytarilgan to'lovlar", 'ru': "Возврат средств"},
    'manager': {'uz': "Menejer", 'ru': "Менеджер"},
    'error': {'uz': "Xatolik yuz berdi", 'ru': "Ошибка"},
    'no_data': {'uz': "Ma'lumot topilmadi", 'ru': "Данные не найдены"},
    'currency': {'uz': "so'm", 'ru': "сум"},
  };

  String t(String key) => _words[key]?[lang] ?? key;

  Future<List<dynamic>> getReturns() async {
    try {
      final response = await http.get(
        Uri.parse('https://atko.tech/smart_kids_app_api/public/api/kids/paymarts/repeat'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: getReturns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Yuklanish jarayonida shimmer effektini ko'rsatamiz
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return Center(child: Text("${t('error')}: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(t('no_data')));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => _buildReturnCard(snapshot.data![index]),
          );
        },
      ),
    );
  }

  // --- SHIMMER EFFEKTI ---
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: 6, // 6 ta "yolg'onchi" element ko'rsatamiz
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120, // Taxminiy card balandligi
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  // --- ASOSIY CARD ---
  Widget _buildReturnCard(dynamic item) {
    DateTime dateTime = DateTime.parse(item['created_at']);
    String formattedDate = DateFormat('dd.MM.yyyy | HH:mm').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['kids']['full_name'] ?? '---',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D3436)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("- ${item['amount']} ${t('currency')}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text("${t('manager')}: ${item['kassir']}", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F2F6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
              Text(formattedDate, style: const TextStyle(color: Colors.black38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}