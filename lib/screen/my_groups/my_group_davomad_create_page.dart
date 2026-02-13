import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class MyGroupDavomadCreatePage extends StatefulWidget {
  final int id;

  const MyGroupDavomadCreatePage({super.key, required this.id});

  @override
  State<MyGroupDavomadCreatePage> createState() =>
      _MyGroupDavomadCreatePageState();
}

class _MyGroupDavomadCreatePageState extends State<MyGroupDavomadCreatePage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _students = [];

  // Tilni aniqlash
  late String currentLang;

  // Matnlar lug'ati
  final Map<String, Map<String, String>> _words = {
    'uz': {
      'title': 'Davomad olish',
      'submit': 'Tasdiqlash',
      'error_fetch': 'Ma’lumotlarni yuklashda xatolik',
      'error_network': 'Tarmoq bilan aloqa yo‘q',
      'error_save': 'Saqlashda xatolik yuz berdi',
      'success': 'Muvaffaqiyatli saqlandi',
      'keldi': 'Keldi',
      'kechikdi': 'Kechikdi',
      'sababli': 'Sababli',
      'sababsiz': 'Sababsiz',
    },
    'ru': {
      'title': 'Отметка посещаемости',
      'submit': 'Подтвердить',
      'error_fetch': 'Ошибка при загрузке данных',
      'error_network': 'Нет связи с сетью',
      'error_save': 'Ошибка при сохранении',
      'success': 'Успешно сохранено',
      'keldi': 'Пришел',
      'kechikdi': 'Опоздал',
      'sababli': 'По причине',
      'sababsiz': 'Без причины',
    },
  };

  final Map<String, Color> _statusMap = {
    'keldi': Colors.green,
    'kechikdi': Colors.orange,
    'sababli': Colors.blue,
    'sababsiz': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    // GetStorage'dan tilni olish, agar yo'q bo'lsa default 'uz'
    currentLang = _storage.read('lang') ?? 'uz';
    _fetchStudents();
  }

  // Lug'atdan so'zni olish uchun yordamchi funksiya
  String _t(String key) => _words[currentLang]?[key] ?? key;

  // ================= FETCH =================

  Future<void> _fetchStudents() async {
    final token = _storage.read('token');

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConst.apiUrl}/kid/group/${widget.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        setState(() {
          _students = decoded;
          for (var s in _students) {
            s['status'] = s['status'] ?? 'keldi';
          }
          _isLoading = false;
        });
      } else {
        _showError(_t('error_fetch'));
      }
    } catch (e) {
      _showError(_t('error_network'));
    }
  }

  // ================= SUBMIT =================

  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final token = _storage.read('token');

    final data = {
      "attendances": _students
          .map(
            (s) => {
              "kid_id": s['kid_id'],
              "group_id": widget.id,
              "status": s['status'],
            },
          )
          .toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/kid/store'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);

        // Muvaffaqiyatli xabarini ko'rsatish (ixtiyoriy)
        Get.snackbar(
          currentLang == 'uz' ? "Tayyor" : "Готово",
          _t('success'),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        _showError(_t('error_save'));
      }
    } catch (e) {
      _showError(_t('error_network'));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ================= ERROR =================

  void _showError(String message) {
    if (!mounted) return;

    Get.snackbar(
      currentLang == 'uz' ? "Xato" : "Ошибка",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );

    setState(() {
      _isSubmitting = false;
      _isLoading = false;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('title')
        ),
      ),
      body: _isLoading ? _buildShimmer() : _buildList(),
      bottomNavigationBar: _buildBottomBtn(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final s = _students[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _statusMap.keys.map((st) {
                    bool selected = s['status'] == st;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _students[index]['status'] = st;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _statusMap[st] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? _statusMap[st]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _t(st), // Statuslarni tarjima qilish
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBtn() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _t('submit'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
