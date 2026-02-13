import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class ChildDavomadHistoryPage extends StatefulWidget {
  final int id; // Bu kidId

  const ChildDavomadHistoryPage({super.key, required this.id});

  @override
  State<ChildDavomadHistoryPage> createState() => _ChildDavomadHistoryPageState();
}

class _ChildDavomadHistoryPageState extends State<ChildDavomadHistoryPage> {
  final GetStorage _storage = GetStorage();
  bool _isLoading = true;
  Map<String, dynamic>? _kidInfo;
  List<dynamic> _history = [];
  late String currentLang;

  // Lug'at
  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': 'Davomat tarixi',
      'group': 'Guruh',
      'reason': 'Sabab',
      'no_reason': 'Izoh yo\'q',
      'keldi': 'Keldi',
      'kechikdi': 'Kechikdi',
      'sababli': 'Sababli',
      'sababsiz': 'Sababsiz',
      'empty': 'Tarix mavjud emas',
      'error': 'Ma’lumot yuklashda xato',
    },
    'ru': {
      'title': 'История посещаемости',
      'group': 'Группа',
      'reason': 'Причина',
      'no_reason': 'Нет описания',
      'keldi': 'Пришел',
      'kechikdi': 'Опоздал',
      'sababli': 'По причине',
      'sababsiz': 'Без причины',
      'empty': 'История отсутствует',
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
    final url = '${ApiConst.apiUrl}/kid/kid/davomad/show/${widget.id}';

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
          _kidInfo = data['kid_info'];
          _history = data['attendance_history'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
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
          : Column(
        children: [
          if (_kidInfo != null) _buildKidHeader(),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  // Bolaning ismi va umumiy ma'lumoti qismi
  Widget _buildKidHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(_kidInfo!['full_name'][0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_kidInfo!['full_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("ID: ${_kidInfo!['id']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Timeline ko'rinishidagi tarix
  Widget _buildTimeline() {
    if (_history.isEmpty) return Center(child: Text(_t('empty')));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final DateTime date = DateTime.parse(item['date']);
        final Color statusColor = _getStatusColor(item['status']);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chap tomondagi chiziq va nuqta
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
                if (index != _history.length - 1)
                  Container(width: 2, height: 80, color: Colors.grey.withOpacity(0.3)),
              ],
            ),
            const SizedBox(width: 15),
            // O'ng tomondagi ma'lumot kartasi
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd.MM.yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(_t(item['status']), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("${_t('group')}: ${item['group_name']}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                    if (item['reason'] != null) ...[
                      const SizedBox(height: 4),
                      Text("${_t('reason')}: ${item['reason']}", style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'keldi': return Colors.green;
      case 'kechikdi': return Colors.orange;
      case 'sababli': return Colors.blue;
      case 'sababsiz': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}