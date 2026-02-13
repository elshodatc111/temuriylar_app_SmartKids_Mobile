import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class HodimGuruhlarTarixi extends StatefulWidget {
  final int id; // Bu user_id (tarbiyachining id-si)
  const HodimGuruhlarTarixi({super.key, required this.id});

  @override
  State<HodimGuruhlarTarixi> createState() => _HodimGuruhlarTarixiState();
}

class _HodimGuruhlarTarixiState extends State<HodimGuruhlarTarixi> {
  final GetStorage _storage = GetStorage();
  bool _isLoading = true;
  List<dynamic> _history = [];
  late String currentLang;

  // Lug'at
  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': 'Guruhlar tarixi',
      'added': 'Biriktirildi',
      'removed': 'O‘chirildi',
      'active': 'Hozirda faol',
      'by_admin': 'Admin:',
      'date': 'Sana:',
      'no_data': 'Tarix mavjud emas',
      'error': 'Yuklashda xatolik',
    },
    'ru': {
      'title': 'История групп',
      'added': 'Прикреплен',
      'removed': 'Удален',
      'active': 'Сейчас активен',
      'by_admin': 'Админ:',
      'date': 'Дата:',
      'no_data': 'История отсутствует',
      'error': 'Ошибка загрузки',
    }
  };

  @override
  void initState() {
    super.initState();
    currentLang = _storage.read('lang') ?? 'uz';
    _fetchHistory();
  }

  String _t(String key) => _words[currentLang]?[key] ?? key;

  Future<void> _fetchHistory() async {
    final token = _storage.read('token');
    final url = '${ApiConst.apiUrl}/emploes/tarbiyachi/grouups/${widget.id}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _history = data['groups'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Xatolik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title')),
      ),
      body: _isLoading
          ? _buildShimmer()
          : _history.isEmpty
          ? Center(child: Text(_t('no_data')))
          : _buildTimelineList(),
    );
  }

  Widget _buildTimelineList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final bool isActive = item['status'] == 'active';
        final Color statusColor = isActive ? Colors.green : Colors.redAccent;

        return IntrinsicHeight(
          child: Row(
            children: [
              // Timeline chizig'i
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 3),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: index == _history.length - 1
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Ma'lumot kartasi
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guruh nomi va Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['group']['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? _t('active') : _t('removed'),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Qo'shilgan vaqti
                      _buildInfoRow(
                        Icons.add_circle_outline,
                        Colors.blue,
                        "${_t('added')}: ${item['add_data']}",
                        "${_t('by_admin')} ${item['admin']['name']}",
                      ),

                      // Agar o'chirilgan bo'lsa, o'chirilgan vaqti
                      if (!isActive && item['delete_data'] != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.remove_circle_outline,
                          Colors.redAccent,
                          "${_t('removed')}: ${item['delete_data']}",
                          "${_t('by_admin')} ${item['admin_delete']?['name'] ?? '---'}",
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}