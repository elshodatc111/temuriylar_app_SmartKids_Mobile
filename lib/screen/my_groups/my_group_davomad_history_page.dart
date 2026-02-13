import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class MyGroupDavomadHistoryPage extends StatefulWidget {
  final int id;

  const MyGroupDavomadHistoryPage({super.key, required this.id});

  @override
  State<MyGroupDavomadHistoryPage> createState() =>
      _MyGroupDavomadHistoryPageState();
}

class _MyGroupDavomadHistoryPageState extends State<MyGroupDavomadHistoryPage> {
  final GetStorage _storage = GetStorage();
  bool _isLoading = true;
  List<dynamic> _historyData = [];
  late String currentLang;

  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': 'Davomad tarixi',
      'keldi': 'Keldi',
      'kelmadi': 'Kelmadi',
      'sababli': 'Sababli',
      'sababsiz': 'Sababsiz',
      'stats': 'Statistika',
      'no_data': 'Ma’lumot topilmadi',
      'error': 'Xatolik yuz berdi',
    },
    'ru': {
      'title': 'История посещаемости',
      'keldi': 'Пришел',
      'kelmadi': 'Не пришел',
      'sababli': 'По причине',
      'sababsiz': 'Без причины',
      'stats': 'Статистика',
      'no_data': 'Данные не найдены',
      'error': 'Произошла ошибка',
    },
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
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kid/group/history/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _historyData = decoded['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('title'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading ? _buildShimmer() : _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    if (_historyData.isEmpty) {
      return Center(child: Text(_t('no_data')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyData.length,
      itemBuilder: (context, monthIndex) {
        final monthItem = _historyData[monthIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Text(
                monthItem['month'], // Masalan: 2026-02
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            ...monthItem['students'].map<Widget>((student) {
              return _buildStudentCard(student);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Text(
            student['full_name'][0].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student['full_name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statMiniItem(student['stats']['keldi'], Colors.green),
              _statMiniItem(student['stats']['kelmadi'], Colors.orange),
              _statMiniItem(student['stats']['sababli'], Colors.blue),
              _statMiniItem(student['stats']['sababsiz'], Colors.red),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: student['days'].isEmpty
                ? Center(
                    child: Text(
                      _t('no_data'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student['days'].map<Widget>((day) {
                      return _buildDayChip(day);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statMiniItem(int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDayChip(dynamic day) {
    // Sanani formatlash (2026-02-13)
    DateTime date = DateTime.parse(day['date']);
    String formattedDate = DateFormat('dd.MM').format(date);

    Color statusColor;
    switch (day['status']) {
      case 'keldi':
        statusColor = Colors.green;
        break;
      case 'sababli':
        statusColor = Colors.blue;
        break;
      case 'sababsiz':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            _t(day['status']),
            style: TextStyle(
              fontSize: 9,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}
