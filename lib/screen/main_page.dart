import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/const/menu_const.dart';
import 'package:smart_kids_app_end/screen/profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GetStorage box = GetStorage();
  bool _isLoading = true;
  Map<String, dynamic>? _groupStatus;
  Map<String, dynamic>? _staffStatus;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // 1. Ma'lumotlarni yuklash (Kesh va API mantiqi)
  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (mounted) setState(() => _isLoading = true);
    final results = await Future.wait([
      _fetchWithCache(
        'group_status',
        '${ApiConst.apiUrl}/kid/attendance/check-today',
        forceRefresh,
      ),
      _fetchWithCache(
        'staff_status',
        '${ApiConst.apiUrl}/user/attendance/check-today',
        forceRefresh,
      ),
    ]);
    if (mounted) {
      setState(() {
        _groupStatus = results[0];
        _staffStatus = results[1];
        _isLoading = false;
      });
    }
  }

  // 2. 30 daqiqalik kesh tizimi
  Future<Map<String, dynamic>?> _fetchWithCache(
    String key,
    String url,
    bool force,
  ) async {
    final String token = box.read('token') ?? '';
    final String cacheKey = '${key}_data';
    final String timeKey = '${key}_time';

    if (!force) {
      final cachedData = box.read(cacheKey);
      final cachedTime = box.read(timeKey);
      if (cachedData != null && cachedTime != null) {
        if (DateTime.now().difference(DateTime.parse(cachedTime)).inMinutes <
            30) {
          return cachedData is String ? json.decode(cachedData) : cachedData;
        }
      }
    }
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
        box.write(cacheKey, data);
        box.write(timeKey, DateTime.now().toIso8601String());
        return data;
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    return box.read(cacheKey);
  }

  @override
  Widget build(BuildContext context) {
    final String lang = box.read('lang') ?? 'uz';
    final profile = box.read('profile');
    final String userRole =
        profile?['type']?.toString().toLowerCase() ?? 'hodim';

    // Foydalanuvchi roliga qarab menyularni filtrlash
    final accessibleMenus = MenuConst.items.where((item) {
      final List roles = item['roles'] as List;
      return roles.contains(userRole);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text(
          "Smart Kids",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const ProfilePage()),
            icon: const Icon(
              Icons.account_circle,
              size: 30,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadDashboardData(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCards(lang),
            const SizedBox(height: 24),
            Text(
              lang == 'uz' ? "Asosiy bo'limlar" : "Основные разделы",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 12),
            ...accessibleMenus
                .map((item) => _buildMenuItem(item, lang))
                .toList(),
          ],
        ),
      ),
    );
  }

  // 3. Statistika kartalari
  Widget _buildStatCards(String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: lang == 'uz'
                ? "Davomat to'ldirilmadi"
                : "Посещаемость не заполнена",
            subtitle: _groupStatus?['date'] ?? "--",
            value: "${_groupStatus?['count'] ?? 0}",
            icon: Icons.group_off_rounded,
            color: Colors.orange,
            onTap: () {
              final List items = _groupStatus?['groups'] ?? [];
              if (items.isNotEmpty) {
                _showListModal(
                  lang == 'uz'
                      ? "Davomat olinmagan guruhlar"
                      : "Неотмеченные группы",
                  items,
                  (i) => i['name'],
                  (i) => "",
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: lang == 'uz' ? "Xodimlar" : "Сотрудники",
            subtitle: _staffStatus?['is_completed'] == true
                ? (lang == 'uz' ? "Davomat olindi" : "Посещаемость отмечена")
                : (lang == 'uz'
                      ? "Davomat olinmadi"
                      : "Посещаемость не отмечена"),
            value: "${_staffStatus?['total_count'] ?? 0}",
            icon: Icons.badge_outlined,
            color: _staffStatus?['is_completed'] == true
                ? Colors.green
                : Colors.redAccent,
            onTap: () {
              final List items = _staffStatus?['list'] ?? [];
              if (items.isNotEmpty) {
                _showListModal(
                  lang == 'uz'
                      ? "Intizomni buzgan xodimlar"
                      : "Нарушители дисциплины",
                  items,
                  (i) => i['name'],
                  (i) => "${i['type']} | ${i['status']}",
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Modal oyna (70% balandlik cheklovi bilan)
  void _showListModal(
    String title,
    List items,
    String Function(dynamic) nameMap,
    String Function(dynamic) subMap,
  ) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(
                        nameMap(item)[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    title: Text(
                      nameMap(item),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: subMap(item).isEmpty
                        ? null
                        : Text(
                            subMap(item),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                    trailing: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // 5. Menyu navigatsiyasi (Xatolik tuzatilgan)
  Widget _buildMenuItem(dynamic item, String lang) {
    final Color itemColor = item['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item['icon'], color: itemColor, size: 28),
        ),
        title: Text(
          lang == 'uz' ? item['title_uz'] : item['title_ru'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {
          final dynamic target = item['page'];
          if (target != null && target is Widget) {
            // Xatolikni bartaraf etish uchun funksiya ko'rinishida chaqiramiz
            Get.to(() => target);
          } else {
            Get.snackbar(
              lang == 'uz' ? "Tez kunda" : "Скоро",
              lang == 'uz' ? "Ish jarayonida" : "В разработке",
            );
          }
        },
      ),
    );
  }
}
